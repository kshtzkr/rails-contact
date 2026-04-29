module Rails
  module Contact
    class ContactPhone < ApplicationRecord
      self.table_name = "rails_contact_contact_phones"

      belongs_to :contact, class_name: "Rails::Contact::Contact", inverse_of: :phones

      validates :value, presence: true

      before_validation :normalize_value

      def primary?
        primary
      end

      private

      def normalize_value
        return if value.blank?

        parsed = Phonelib.parse(value)
        self.e164 = parsed.e164 || value
      end
    end
  end
end
