require "rails_helper"

RSpec.describe Rails::Contact::MergeContactsService do
  it "merges source into target and deletes source" do
    source = create(:rails_contact_contact, given_name: "Source", family_name: nil)
    source.emails.create!(value: "source@example.com", label: "work", primary: true)
    source.labels << Rails::Contact::Label.create!(name: "lead")

    target = create(:rails_contact_contact, given_name: "Target", family_name: "User")
    target.emails.create!(value: "target@example.com", label: "work", primary: true)

    described_class.new(source_id: source.id, target_id: target.id).call

    expect(Rails::Contact::Contact.exists?(source.id)).to be(false)
    merged = Rails::Contact::Contact.find(target.id)
    expect(merged.emails.pluck(:value)).to include("source@example.com", "target@example.com")
    expect(merged.labels.pluck(:name)).to include("lead")
  end

  it "does not duplicate matching nested records" do
    source = create(:rails_contact_contact)
    source.emails.create!(value: "same@example.com", label: "work", primary: true)
    target = create(:rails_contact_contact)
    target.emails.create!(value: "same@example.com", label: "work", primary: true)

    described_class.new(source_id: source.id, target_id: target.id).call

    expect(Rails::Contact::Contact.find(target.id).emails.where(value: "same@example.com").count).to eq(1)
  end

  it "raises when source equals target" do
    target = create(:rails_contact_contact)
    expect do
      described_class.new(source_id: target.id, target_id: target.id).call
    end.to raise_error(ArgumentError)
  end
end
