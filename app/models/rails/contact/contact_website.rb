module Rails
  module Contact
    class ContactWebsite < ApplicationRecord
      self.table_name = "rails_contact_contact_websites"

      belongs_to :contact, class_name: "Rails::Contact::Contact", inverse_of: :websites

      validates :url, presence: true
    end
  end
end
