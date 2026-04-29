module Rails
  module Contact
    class Label < ApplicationRecord
      self.table_name = "rails_contact_labels"

      has_many :contact_labels, class_name: "Rails::Contact::ContactLabel", dependent: :destroy, inverse_of: :label
      has_many :contacts, through: :contact_labels, source: :contact

      validates :name, presence: true, uniqueness: { case_sensitive: false }

      before_validation :normalize_name

      private

      def normalize_name
        self.name = name.to_s.strip
      end
    end
  end
end
