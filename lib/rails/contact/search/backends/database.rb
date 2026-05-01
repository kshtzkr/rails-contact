module Rails
  module Contact
    module Search
      module Backends
        class Database
          def search(query, filters, page:, per_page:)
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

          def apply_filters(scope, filters)
            scoped = scope
            scoped = scoped.where(current_city: filters["city"]) if filters["city"].present?
            scoped = scoped.where(region_name: filters["region"]) if filters["region"].present?
            scoped = scoped.where(starred: ActiveModel::Type::Boolean.new.cast(filters["starred"])) if filters["starred"].present?
            if filters["sync_eligible"].present?
              scoped = scoped.where(sync_eligible: ActiveModel::Type::Boolean.new.cast(filters["sync_eligible"]))
            end
            scoped
          end
        end
      end
    end
  end
end
