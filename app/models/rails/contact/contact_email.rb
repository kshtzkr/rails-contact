module Rails
  module Contact
    class ContactEmail < ApplicationRecord
      self.table_name = "rails_contact_contact_emails"

      belongs_to :contact, class_name: "Rails::Contact::Contact", inverse_of: :emails

      validates :value, presence: true
      validates :value, format: {with: URI::MailTo::EMAIL_REGEXP}

      before_validation :normalize_value

      def primary?
        primary
      end

      private

      def normalize_value
        self.value = value.to_s.strip.downcase.presence
      end
    end
  end
end
