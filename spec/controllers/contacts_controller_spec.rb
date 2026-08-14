require "rails_helper"

RSpec.describe Rails::Contact::ContactsController do
  let(:controller) { described_class.new }

  describe "private filter params" do
    # city joined region as a multi-select in 0.1.18, so a scalar from an old
    # bookmark is coerced to a one-element array rather than kept as a string.
    it "permits sync_eligible and coerces scalar city/region to arrays" do
      controller.params = ActionController::Parameters.new(city: "Delhi", region: "Europe", sync_eligible: "true", x: "1")
      permitted = controller.send(:filter_params)
      expect(permitted.to_h).to eq({ "city" => [ "Delhi" ], "region" => [ "Europe" ], "sync_eligible" => "true" })
    end

    it "permits multi-select city[], region[] and csv_import_id[] arrays" do
      controller.params = ActionController::Parameters.new(city: [ "Pune", "Delhi" ], region: [ "Europe", "Asia" ], csv_import_id: [ "5", "7" ])
      permitted = controller.send(:filter_params)
      expect(permitted.to_h).to eq({ "city" => [ "Pune", "Delhi" ], "region" => [ "Europe", "Asia" ], "csv_import_id" => [ "5", "7" ] })
    end

    it "strips the blank a city multi-select submits, and drops it when only blanks arrive" do
      controller.params = ActionController::Parameters.new(city: [ "", "Pune" ])
      expect(controller.send(:filter_params).to_h).to eq({ "city" => [ "Pune" ] })

      controller.params = ActionController::Parameters.new(city: [ "" ])
      expect(controller.send(:filter_params).to_h).to eq({})
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

  describe "configured metadata filter params" do
    around do |example|
      config = Rails::Contact.configuration
      original_filters = config.metadata_filters
      original_sorts = config.metadata_sorts
      config.metadata_filters = {
        "tier" => { key: "quality_tier", type: :values, allowed: %w[hot warm] },
        "min_pax" => { key: "pax", type: :min_integer }
      }
      config.metadata_sorts = { "score" => { key: "score" } }
      example.run
    ensure
      config.metadata_filters = original_filters
      config.metadata_sorts = original_sorts
    end

    it "permits configured array, scalar and sort params" do
      controller.params = ActionController::Parameters.new(
        tier: [ "hot" ], min_pax: "4", sort: "score", unrelated: "x"
      )
      permitted = controller.send(:filter_params)
      expect(permitted.to_h).to eq({ "tier" => [ "hot" ], "min_pax" => "4", "sort" => "score" })
    end

    it "normalizes configured multi-selects like region (scalar coercion + blank strip)" do
      controller.params = ActionController::Parameters.new(tier: "warm")
      expect(controller.send(:filter_params).to_h).to eq({ "tier" => [ "warm" ] })

      controller.params = ActionController::Parameters.new(tier: [ "" ])
      expect(controller.send(:filter_params).to_h).to eq({})
    end

    it "does not permit sort when no metadata sorts are configured" do
      Rails::Contact.configuration.metadata_sorts = {}
      controller.params = ActionController::Parameters.new(sort: "score")
      expect(controller.send(:filter_params).to_h).to eq({})
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
