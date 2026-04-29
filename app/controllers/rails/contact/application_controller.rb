module Rails
  module Contact
    class ApplicationController < ActionController::Base
      protect_from_forgery with: :exception

      private

      def t_flash(key, default:)
        I18n.t("rails_contact.flash.#{key}", default: default)
      end
    end
  end
end
