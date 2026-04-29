module Rails
  module Contact
    class ContactMailer < ApplicationMailer
      def confirmation_instructions(email, token)
        mail_for(email, "Confirmation instructions", token)
      end

      def reset_password_instructions(email, token)
        mail_for(email, "Reset password instructions", token)
      end

      def unlock_instructions(email, token)
        mail_for(email, "Unlock instructions", token)
      end

      def email_changed(email)
        mail(to: email, subject: "Email changed notification")
      end

      def password_changed(email)
        mail(to: email, subject: "Password changed notification")
      end

      private

      def mail_for(email, subject, token)
        Rails.logger.info("[rails-contact] #{subject} for #{email}: #{token}")
        mail(to: email, subject: subject)
      end
    end
  end
end
