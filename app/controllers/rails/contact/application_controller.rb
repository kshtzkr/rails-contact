module Rails
  module Contact
    class ApplicationController < ActionController::Base
      protect_from_forgery with: :exception

      layout :rails_contact_layout

      private

      def rails_contact_layout
        Rails::Contact.configuration.inherit_host_layout ? "application" : "rails/contact/application"
      end

      def t_flash(key, default:)
        I18n.t("rails_contact.flash.#{key}", default: default)
      end
    end
  end
end
