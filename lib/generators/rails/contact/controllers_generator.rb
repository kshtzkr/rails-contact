require "rails/generators/base"

module Rails
  module Contact
    module Generators
      class ControllersGenerator < ::Rails::Generators::Base
        source_root File.expand_path("templates", __dir__)

        def copy_controllers
          template "contacts_controller.rb.tt", "app/controllers/rails/contact/contacts_controller.rb"
        end
      end
    end
  end
end
