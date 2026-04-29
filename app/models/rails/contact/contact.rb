require "json"

module Rails
  module Contact
    class Contact < ApplicationRecord
      self.table_name = "rails_contact_contacts"
      attr_accessor :labels_csv

      has_many :emails, class_name: "Rails::Contact::ContactEmail", dependent: :destroy, inverse_of: :contact
      has_many :phones, class_name: "Rails::Contact::ContactPhone", dependent: :destroy, inverse_of: :contact
      has_many :addresses, class_name: "Rails::Contact::ContactAddress", dependent: :destroy, inverse_of: :contact
      has_many :websites, class_name: "Rails::Contact::ContactWebsite", dependent: :destroy, inverse_of: :contact
      has_many :events, class_name: "Rails::Contact::ContactEvent", dependent: :destroy, inverse_of: :contact
      has_many :contact_labels, class_name: "Rails::Contact::ContactLabel", dependent: :destroy, inverse_of: :contact
      has_many :labels, through: :contact_labels, source: :label

      accepts_nested_attributes_for :emails, :phones, :addresses, :websites, :events, allow_destroy: true

      validates :given_name, presence: true

      scope :recent_first, -> { order(updated_at: :desc, id: :desc) }
      scope :sync_window, lambda {
        recent_first.limit(Rails::Contact.configuration.google_max_contacts)
      }

      def full_name
        [ given_name, family_name ].compact.join(" ").strip
      end

      def primary_email
        emails.find(&:primary?) || emails.first
      end

      def primary_phone
        phones.find(&:primary?) || phones.first
      end

      def meta(key)
        metadata_hash[key.to_s]
      end

      def set_labels_from_csv!(csv_string)
        names = csv_string.to_s.split(",").map(&:strip).reject(&:empty?).uniq
        self.labels = names.map { |name| Rails::Contact::Label.find_or_create_by!(name: name) }
      end

      def labels_csv
        labels.pluck(:name).sort.join(", ")
      end

      def metadata_hash
        value = metadata
        return value if value.is_a?(Hash)
        return {} if value.blank?

        parsed = JSON.parse(value)
        parsed.is_a?(Hash) ? parsed : {}
      rescue JSON::ParserError
        {}
      end
    end
  end
end
