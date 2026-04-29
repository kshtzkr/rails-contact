module Rails
  module Contact
    module Routing
      # Mount helper that normalizes singular/plural resource names.
      # Example:
      #   rails_contact_for :contact  -> /contacts
      #   rails_contact_for :contacts -> /contacts
      def rails_contact_for(resource = :contacts, at: nil, as: "rails_contact")
        normalized = resource.to_s.sub(%r{\A/+}, "").pluralize
        mount_path = at.presence || "/#{normalized}"
        mount Rails::Contact::Engine => mount_path, as: as
      end
    end
  end
end

ActionDispatch::Routing::Mapper.include(Rails::Contact::Routing)
