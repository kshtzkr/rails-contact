module Rails
  module Contact
    module Search
      module Backends
        class Database
          # Cap user input so the LIKE pattern stays bounded; 200 chars covers
          # any realistic name/email/phone substring.
          MAX_QUERY_LENGTH = 200

          def search(query, filters, page:, per_page:)
            query = sanitize_query(query)
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

            scoped
          end
        end
      end
    end
  end
end
