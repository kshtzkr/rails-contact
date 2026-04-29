module Rails
  module Contact
    class ContactEvent < ApplicationRecord
      self.table_name = "rails_contact_contact_events"

      belongs_to :contact, class_name: "Rails::Contact::Contact", inverse_of: :events

      validates :event_type, presence: true
    end
  end
end
