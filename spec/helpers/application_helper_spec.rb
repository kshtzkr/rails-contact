require "rails_helper"

RSpec.describe Rails::Contact::ApplicationHelper, type: :helper do
  it "returns initials for a contact" do
    contact = Rails::Contact::Contact.new(given_name: "Ava", family_name: "Stone")
    expect(helper.contact_initials(contact)).to eq("AS")
  end

  it "renders an exact count plainly and a capped one as a floor" do
    expect(helper.contact_count_label(1_005)).to eq("1,005")
    expect(helper.contact_count_label(10_000, true)).to eq("10,000+")
  end

  it "returns fallback chip for blank values" do
    expect(helper.contact_chip(nil)).to eq("-")
    expect(helper.contact_chip("x")).to eq("x")
  end
end
