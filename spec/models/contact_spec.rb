require "rails_helper"

RSpec.describe Rails::Contact::Contact do
  it "builds full_name from given and family names" do
    contact = build(:rails_contact_contact, given_name: "Ravi", family_name: "Shah")
    expect(contact.full_name).to eq("Ravi Shah")
  end

  it "stores and retrieves labels via csv setter" do
    contact = create(:rails_contact_contact)
    contact.set_labels_from_csv!("vip, lead, vip")
    expect(contact.labels.pluck(:name).sort).to eq(%w[lead vip])
    expect(contact.labels_csv).to eq("lead, vip")
  end

  it "returns primary email and primary phone" do
    contact = create(:rails_contact_contact)
    contact.emails.create!(value: "a@example.com", primary: false)
    contact.emails.create!(value: "b@example.com", primary: true)
    contact.phones.create!(value: "+911111111111", e164: "+911111111111", primary: false)
    contact.phones.create!(value: "+922222222222", e164: "+922222222222", primary: true)
    expect(contact.primary_email.value).to eq("b@example.com")
    expect(contact.primary_phone.e164).to eq("+922222222222")
  end

  it "reads metadata through meta helper" do
    contact = create(:rails_contact_contact, metadata: "{\"department\":\"Sales\"}")
    expect(contact.meta(:department)).to eq("Sales")
  end

  it "returns metadata value when metadata is already a hash" do
    contact = Rails::Contact::Contact.new(given_name: "A")
    allow(contact).to receive(:metadata).and_return({ "department" => "Ops" })
    expect(contact.metadata_hash["department"]).to eq("Ops")
  end

  it "handles invalid metadata safely" do
    contact = create(:rails_contact_contact, metadata: "{broken")
    expect(contact.metadata_hash).to eq({})
    expect(contact.meta(:missing)).to be_nil
  end

  it "handles blank metadata safely" do
    contact = create(:rails_contact_contact, metadata: nil)
    expect(contact.metadata_hash).to eq({})
  end

  it "handles non-hash json metadata safely" do
    contact = create(:rails_contact_contact, metadata: "[1, 2, 3]")
    expect(contact.metadata_hash).to eq({})
  end

  it "returns recent contacts in sync window" do
    Rails::Contact.configuration.google_max_contacts = 1
    older = create(:rails_contact_contact, updated_at: 2.days.ago, created_at: 2.days.ago)
    newer = create(:rails_contact_contact, updated_at: Time.current, created_at: Time.current)
    expect(Rails::Contact::Contact.sync_window.pluck(:id)).to eq([ newer.id ])
    expect(older).to be_present
  end
end
