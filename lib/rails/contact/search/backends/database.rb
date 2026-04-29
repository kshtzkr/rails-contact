module Rails
  module Contact
    module Search
      module Backends
        class Database
          def search(query, filters)
            scope = Contact.includes(:emails, :phones).recent_first
            scope = apply_filters(scope, filters)
            return scope.limit(limit) if query.blank?

            wildcard = "%#{query.downcase}%"
            scope.left_joins(:emails, :phones).where(
              "LOWER(rails_contact_contacts.given_name) LIKE :q OR "\
              "LOWER(rails_contact_contacts.family_name) LIKE :q OR "\
              "LOWER(rails_contact_contact_emails.value) LIKE :q OR "\
              "rails_contact_contact_phones.e164 LIKE :raw",
              q: wildcard,
              raw: "%#{query}%"
            ).distinct.limit(limit)
          end

          private

          def apply_filters(scope, filters)
            scoped = scope
            scoped = scoped.where(current_city: filters["city"]) if filters["city"].present?
            scoped = scoped.where(region_name: filters["region"]) if filters["region"].present?
            if filters["sync_eligible"].present?
              scoped = scoped.where(sync_eligible: ActiveModel::Type::Boolean.new.cast(filters["sync_eligible"]))
            end
            scoped
          end

          def limit
            Rails::Contact.configuration.default_per_page
          end
        end
      end
    end
  end
end
