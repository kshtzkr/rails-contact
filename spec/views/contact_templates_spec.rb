require "rails_helper"

RSpec.describe "contact templates" do
  let(:form_template) { File.read(File.expand_path("../../app/views/rails/contact/_form.html.erb", __dir__)) }
  let(:index_template) { File.read(File.expand_path("../../app/views/rails/contact/index.html.erb", __dir__)) }

  it "contains dynamic nested field hooks in form" do
    expect(form_template).to include("data-add-nested")
    expect(form_template).to include("labels_csv")
    expect(form_template).to include("events")
  end

  it "contains enhanced list columns in index" do
    expect(index_template).to include("Starred")
    expect(index_template).to include("Company")
  end
end
