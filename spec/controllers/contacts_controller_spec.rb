require "rails_helper"

RSpec.describe Rails::Contact::ContactsController do
  let(:controller) { described_class.new }

  describe "private filter params" do
    it "permits city/sync_eligible and coerces a scalar region to an array" do
      controller.params = ActionController::Parameters.new(city: "Delhi", region: "Europe", sync_eligible: "true", x: "1")
      permitted = controller.send(:filter_params)
      expect(permitted.to_h).to eq({ "city" => "Delhi", "region" => [ "Europe" ], "sync_eligible" => "true" })
    end

    it "permits multi-select region[] and csv_import_id[] arrays" do
      controller.params = ActionController::Parameters.new(region: [ "Europe", "Asia" ], csv_import_id: [ "5", "7" ])
      permitted = controller.send(:filter_params)
      expect(permitted.to_h).to eq({ "region" => [ "Europe", "Asia" ], "csv_import_id" => [ "5", "7" ] })
    end

    it "strips the hidden blank a <select multiple> submits" do
      controller.params = ActionController::Parameters.new(csv_import_id: [ "", "7" ])
      permitted = controller.send(:filter_params)
      expect(permitted.to_h).to eq({ "csv_import_id" => [ "7" ] })
    end

    it "drops a multi-select key entirely when only blanks are submitted" do
      controller.params = ActionController::Parameters.new(region: [ "" ])
      permitted = controller.send(:filter_params)
      expect(permitted.to_h).to eq({})
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
