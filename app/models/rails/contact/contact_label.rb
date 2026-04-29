module Rails
  module Contact
    class ContactLabel < ApplicationRecord
      self.table_name = "rails_contact_contact_labels"

      belongs_to :contact, class_name: "Rails::Contact::Contact", inverse_of: :contact_labels
      belongs_to :label, class_name: "Rails::Contact::Label", inverse_of: :contact_labels

      validates :label_id, uniqueness: { scope: :contact_id }
    end
  end
end
