FactoryBot.define do
  factory :rails_contact_contact, class: "Rails::Contact::Contact" do
    given_name { "Ava" }
    family_name { "Stone" }
    current_city { "Delhi" }
    departure_city { "Mumbai" }
    region_name { "Europe" }
    biography { "Test bio" }
    metadata { { "company" => "Acme", "job_title" => "Manager" } }
    sync_eligible { true }
    starred { false }
  end
end
