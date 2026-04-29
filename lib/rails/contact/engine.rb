module Rails
  module Contact
    class Engine < ::Rails::Engine
      isolate_namespace Rails::Contact

      config.generators.test_framework :minitest

      initializer "rails_contact.configure_defaults" do
        Rails::Contact.configuration
      end

      initializer "rails_contact.filter_sensitive_params" do |app|
        app.config.filter_parameters += %i[google_access_token google_refresh_token authorization]
      end

      rake_tasks do
        load File.expand_path("../../tasks/rails/contact_tasks.rake", __dir__)
      end
    end
  end
end
