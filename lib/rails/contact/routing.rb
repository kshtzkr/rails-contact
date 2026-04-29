module Rails
  module Contact
    module Routing
      def rails_contact_for(path = :contacts)
        mount Rails::Contact::Engine => "/#{path}", as: "rails_contact"
      end
    end
  end
end

ActionDispatch::Routing::Mapper.include(Rails::Contact::Routing)
