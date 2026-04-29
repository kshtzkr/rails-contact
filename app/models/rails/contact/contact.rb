module Rails
  module Contact
    class Contact < ApplicationRecord
      self.table_name = "rails_contact_contacts"

      has_many :emails, class_name: "Rails::Contact::ContactEmail", dependent: :destroy, inverse_of: :contact
      has_many :phones, class_name: "Rails::Contact::ContactPhone", dependent: :destroy, inverse_of: :contact
      has_many :addresses, class_name: "Rails::Contact::ContactAddress", dependent: :destroy, inverse_of: :contact

      accepts_nested_attributes_for :emails, :phones, :addresses, allow_destroy: true

      validates :given_name, presence: true

      scope :recent_first, -> { order(updated_at: :desc, id: :desc) }
      scope :sync_window, lambda {
        recent_first.limit(Rails::Contact.configuration.google_max_contacts)
      }

      def full_name
        [given_name, family_name].compact.join(" ").strip
      end

      def primary_email
        emails.find(&:primary?) || emails.first
      end

      def primary_phone
        phones.find(&:primary?) || phones.first
      end
    end
  end
end
