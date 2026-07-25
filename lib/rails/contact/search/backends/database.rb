module Rails
  module Contact
    module Search
      module Backends
        class Database
          # Cap user input so the LIKE pattern stays bounded; 200 chars covers
          # any realistic name/email/phone substring.
          MAX_QUERY_LENGTH = 200

          # Configured metadata keys are interpolated into SQL fragments, so
          # they must be plain identifiers. This is a foot-gun guard for host
          # developers, not a user-input path — params never reach the key.
          METADATA_KEY_FORMAT = /\A[a-zA-Z0-9_]+\z/

          def search(query, filters, page:, per_page:)
            query = sanitize_query(query)
            # Metadata sort cannot combine with free-text search: the search
            # branch below runs SELECT DISTINCT, and PostgreSQL rejects ORDER BY
            # expressions that are not in the select list. Searching means
            # hunting a specific contact anyway, so q results keep recency order.
            filters = filters.except("sort") if query.present?
            offset = (page - 1) * per_page
            scope = Contact.includes(:emails, :phones, :labels).recent_first
            scope = apply_filters(scope, filters)

            if query.blank?
              total = scope.count
              records = scope.offset(offset).limit(per_page).to_a
              return Search::Result.new(records: records, total_count: total, page: page, per_page: per_page)
            end

            wildcard = "%#{query.downcase}%"
            filtered = scope.left_joins(:emails, :phones, :labels).where(
              "LOWER(rails_contact_contacts.given_name) LIKE :q OR "\
              "LOWER(rails_contact_contacts.family_name) LIKE :q OR "\
              "LOWER(COALESCE(rails_contact_contacts.metadata->>'company', '')) LIKE :q OR "\
              "LOWER(COALESCE(rails_contact_contacts.metadata->>'job_title', '')) LIKE :q OR "\
              "LOWER(rails_contact_contact_emails.value) LIKE :q OR "\
              "rails_contact_contact_phones.e164 LIKE :raw OR "\
              "LOWER(rails_contact_labels.name) LIKE :q",
              q: wildcard,
              raw: "%#{query}%"
            ).distinct
            total = filtered.count(:id)
            records = filtered.offset(offset).limit(per_page).to_a
            Search::Result.new(records: records, total_count: total, page: page, per_page: per_page)
          end

          private

          # Escape LIKE metacharacters (% _ \) so a user typing "%" can't widen
          # the match to every row, and cap length to keep the pattern bounded.
          # The backend builds raw "%…%" LIKE patterns, so this guard belongs
          # here — host apps should not have to wrap search() to stay safe.
          def sanitize_query(query)
            return query if query.blank?

            ActiveRecord::Base.sanitize_sql_like(query.to_s[0, MAX_QUERY_LENGTH])
          end

          def apply_filters(scope, filters)
            scoped = scope
            scoped = scoped.where(current_city: filters["city"]) if filters["city"].present?
            scoped = scoped.where(region_name: filters["region"]) if filters["region"].present?
            scoped = scoped.where(starred: ActiveModel::Type::Boolean.new.cast(filters["starred"])) if filters["starred"].present?
            if filters["sync_eligible"].present?
              scoped = scoped.where(sync_eligible: ActiveModel::Type::Boolean.new.cast(filters["sync_eligible"]))
            end

            if filters["travel_date_start"].present?
              scoped = scoped.where("metadata->>'travel_date' >= ?", filters["travel_date_start"])
            end

            if filters["travel_date_end"].present?
              scoped = scoped.where("metadata->>'travel_date' <= ?", filters["travel_date_end"])
            end

            if filters["contact_created_at_start"].present?
              scoped = scoped.where("metadata->>'contact_created_at' >= ?", filters["contact_created_at_start"])
            end

            if filters["contact_created_at_end"].present?
              scoped = scoped.where("metadata->>'contact_created_at' <= ?", filters["contact_created_at_end"])
            end

            # csv_import_id is a multi-select filter: it may be a single id or an
            # array of ids. region above is already array-safe via where(region_name:),
            # but this JSON-extraction predicate needs an explicit IN. A single id
            # yields IN ('5'), identical to the old = '5'.
            if filters["csv_import_id"].present?
              ids = Array(filters["csv_import_id"]).map(&:to_s).reject(&:blank?)
              scoped = scoped.where("metadata->>'csv_import_id' IN (?)", ids) if ids.any?
            end

            scoped = apply_metadata_filters(scoped, filters)
            apply_metadata_sort(scoped, filters["sort"])
          end

          # Host-configured filters over Contact#metadata — see
          # Configuration#metadata_filters for the declaration format. Every
          # stored value came from user data (CSV imports, forms), so numeric
          # comparisons never cast blindly: non-numeric values are filtered
          # out by a guard instead of raising.
          def apply_metadata_filters(scoped, filters)
            Rails::Contact.configuration.metadata_filters.each do |param, config|
              value = filters[param.to_s]
              # A blank param means "not filtering" — except for default-on
              # filters (config default: :on), which apply until the user
              # explicitly switches them off with a false-y value ("0").
              next if value.blank? && config[:default] != :on

              key = metadata_key!(config.fetch(:key))
              scoped = case config.fetch(:type)
              when :values      then apply_values_filter(scoped, key, value, config[:allowed])
              when :min_integer then apply_min_filter(scoped, key, value, decimals: false)
              when :min_numeric then apply_min_filter(scoped, key, value, decimals: true)
              when :tag         then apply_tag_filter(scoped, key, value, config.fetch(:tag))
              when :exclude     then apply_exclude_filter(scoped, key, value, config.fetch(:value))
              else
                raise ArgumentError, "unknown metadata filter type #{config[:type].inspect} for #{param.inspect}"
              end
            end
            scoped
          end

          def apply_values_filter(scoped, key, value, allowed)
            values = Array(value).map(&:to_s).reject(&:blank?)
            values &= allowed.map(&:to_s) if allowed
            return scoped if values.empty?

            scoped.where("metadata->>'#{key}' IN (?)", values)
          end

          def apply_min_filter(scoped, key, value, decimals:)
            floor = decimals ? value.to_f : value.to_i
            return scoped unless floor.positive?

            if postgres?(scoped)
              # {0,1} instead of the ? quantifier: Rails' bind sanitizer counts
              # every literal ? in the fragment as a placeholder, even inside a
              # quoted regex.
              pattern = decimals ? "^[0-9]+(\\.[0-9]+){0,1}$" : "^[0-9]+$"
              cast = decimals ? "numeric" : "int"
              scoped.where("metadata->>'#{key}' ~ '#{pattern}' AND (metadata->>'#{key}')::#{cast} >= ?", floor)
            else
              # SQLite (test harness): CAST never raises — junk casts to 0,
              # which a positive floor excludes on its own.
              scoped.where("CAST(metadata->>'#{key}' AS REAL) >= ?", floor)
            end
          end

          def apply_tag_filter(scoped, key, value, tag)
            return scoped unless ActiveModel::Type::Boolean.new.cast(value)

            if postgres?(scoped)
              scoped.where("metadata->'#{key}' @> ?", [ tag ].to_json)
            else
              scoped.where(
                "EXISTS (SELECT 1 FROM json_each(rails_contact_contacts.metadata, '$.#{key}') WHERE json_each.value = ?)",
                tag
              )
            end
          end

          # Hide rows whose metadata key equals the configured value. Built
          # for default-on filters (\"hide test data\"): a nil param arrives
          # here only when the config says default: :on, and nil casts to
          # nil (not false), so the exclusion applies; an explicit "0"
          # switches it off. Rows MISSING the key must pass — unclassified
          # legacy data is not test data.
          def apply_exclude_filter(scoped, key, value, excluded)
            return scoped if value.present? && ActiveModel::Type::Boolean.new.cast(value) == false

            if postgres?(scoped)
              scoped.where("metadata->>'#{key}' IS DISTINCT FROM ?", excluded.to_s)
            else
              # SQLite (test harness): IS DISTINCT FROM needs 3.39+.
              scoped.where("COALESCE(metadata->>'#{key}', '') <> ?", excluded.to_s)
            end
          end

          # Descending sort over a numeric metadata key; rows with a
          # non-numeric or missing value sink to the bottom, recency breaks
          # ties. Only sorts declared in Configuration#metadata_sorts apply —
          # an unknown ?sort= value is ignored.
          def apply_metadata_sort(scoped, sort_param)
            sort = Rails::Contact.configuration.metadata_sorts[sort_param.to_s]
            return scoped unless sort

            key = metadata_key!(sort.fetch(:key))
            order = if postgres?(scoped)
              "CASE WHEN metadata->>'#{key}' ~ '^[0-9]+(\\.[0-9]+){0,1}$' " \
                "THEN (metadata->>'#{key}')::numeric ELSE -1 END DESC, " \
                "rails_contact_contacts.created_at DESC"
            else
              "CAST(metadata->>'#{key}' AS REAL) DESC, rails_contact_contacts.created_at DESC"
            end
            scoped.reorder(Arel.sql(order))
          end

          def metadata_key!(key)
            key = key.to_s
            unless METADATA_KEY_FORMAT.match?(key)
              raise ArgumentError, "metadata filter key #{key.inspect} must match #{METADATA_KEY_FORMAT.inspect}"
            end

            key
          end

          def postgres?(scoped)
            scoped.klass.connection.adapter_name.match?(/postgres/i)
          end
        end
      end
    end
  end
end
