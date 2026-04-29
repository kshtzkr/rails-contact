module Rails
  module Contact
    class ContactAddress < ApplicationRecord
      self.table_name = "rails_contact_contact_addresses"

      belongs_to :contact, class_name: "Rails::Contact::Contact", inverse_of: :addresses
    end
  end
end
