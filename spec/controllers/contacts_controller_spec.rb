require "rails_helper"

RSpec.describe Rails::Contact::ContactsController do
  let(:controller) { described_class.new }

  describe "private filter params" do
    it "permits city/region/sync_eligible keys" do
      controller.params = ActionController::Parameters.new(city: "Delhi", region: "Europe", sync_eligible: "true", x: "1")
      permitted = controller.send(:filter_params)
      expect(permitted.to_h).to eq({ "city" => "Delhi", "region" => "Europe", "sync_eligible" => "true" })
    end
  end

  describe "association defaults" do
    it "builds default nested associations" do
      contact = Rails::Contact::Contact.new(given_name: "X")
      controller.instance_variable_set(:@contact, contact)
      controller.send(:build_default_associations)
      expect(contact.emails.size).to be >= 2
      expect(contact.phones.size).to be >= 2
      expect(contact.addresses.size).to eq(1)
      expect(contact.websites.size).to eq(1)
      expect(contact.events.size).to eq(1)
    end
  end
end
