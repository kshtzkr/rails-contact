require "rails/generators/base"

module Rails
  module Contact
    module Generators
      class ViewsGenerator < ::Rails::Generators::Base
        source_root File.expand_path("../../../../app/views", __dir__)

        def copy_views
          directory "rails/contact/contacts", "app/views/rails_contact/contacts"
        end
      end
    end
  end
end
