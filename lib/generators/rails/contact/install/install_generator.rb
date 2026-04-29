require "rails/generators"

module Rails
  module Contact
    module Generators
      class InstallGenerator < ::Rails::Generators::Base
        source_root File.expand_path("templates", __dir__)

        def create_initializer
          template "rails_contact.rb.tt", "config/initializers/rails_contact.rb"
        end

        def mount_engine_route
          route "mount Rails::Contact::Engine => '/contacts', as: 'rails_contact'"
        end
      end
    end
  end
end
