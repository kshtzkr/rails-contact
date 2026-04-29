require_relative "spec_helper"

ENV["RAILS_ENV"] ||= "test"

require "bundler/setup"
require "rails"
require "active_record"
require "active_job"
require "action_controller"
require "action_view"
require "rspec/rails"
require "factory_bot"
require "rails/contact"

require_relative "../app/controllers/concerns/rails/contact/filterable"
require_relative "../app/models/rails/contact/application_record"
require_relative "../app/models/rails/contact/contact"
require_relative "../app/models/rails/contact/contact_email"
require_relative "../app/models/rails/contact/contact_phone"
require_relative "../app/models/rails/contact/contact_address"
require_relative "../app/models/rails/contact/contact_website"
require_relative "../app/models/rails/contact/contact_event"
require_relative "../app/models/rails/contact/label"
require_relative "../app/models/rails/contact/contact_label"
require_relative "../app/helpers/rails/contact/application_helper"
require_relative "../app/controllers/rails/contact/application_controller"
require_relative "../app/controllers/rails/contact/contacts_controller"
require_relative "../app/jobs/rails/contact/application_job"
require_relative "../app/jobs/rails/contact/index_contact_job"

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

ActiveRecord::Schema.define do
  create_table :rails_contact_contacts, force: true do |t|
    t.string :given_name, null: false
    t.string :family_name
    t.string :region_name
    t.string :departure_city
    t.string :current_city
    t.string :google_resource_name
    t.string :google_etag
    t.string :photo_url
    t.datetime :google_last_modified_at
    t.datetime :last_synced_at
    t.boolean :sync_eligible, default: true
    t.boolean :starred, default: false
    t.text :biography
    t.text :metadata
    t.timestamps
  end

  create_table :rails_contact_contact_emails, force: true do |t|
    t.integer :contact_id, null: false
    t.string :value, null: false
    t.string :label
    t.boolean :primary, default: false
    t.timestamps
  end

  create_table :rails_contact_contact_phones, force: true do |t|
    t.integer :contact_id, null: false
    t.string :value, null: false
    t.string :e164
    t.string :label
    t.boolean :primary, default: false
    t.timestamps
  end

  create_table :rails_contact_contact_addresses, force: true do |t|
    t.integer :contact_id, null: false
    t.string :city
    t.string :departure_city
    t.text :formatted_value
    t.string :label
    t.timestamps
  end

  create_table :rails_contact_contact_websites, force: true do |t|
    t.integer :contact_id, null: false
    t.string :url, null: false
    t.string :label
    t.timestamps
  end

  create_table :rails_contact_contact_events, force: true do |t|
    t.integer :contact_id, null: false
    t.string :event_type, null: false
    t.date :event_date
    t.string :label
    t.timestamps
  end

  create_table :rails_contact_labels, force: true do |t|
    t.string :name, null: false
    t.timestamps
  end

  create_table :rails_contact_contact_labels, force: true do |t|
    t.integer :contact_id, null: false
    t.integer :label_id, null: false
    t.timestamps
  end
end

ActiveJob::Base.queue_adapter = :test

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
  FactoryBot.find_definitions

  config.before do
    Rails::Contact::ContactLabel.delete_all
    Rails::Contact::Label.delete_all
    Rails::Contact::ContactEvent.delete_all
    Rails::Contact::ContactWebsite.delete_all
    Rails::Contact::ContactAddress.delete_all
    Rails::Contact::ContactPhone.delete_all
    Rails::Contact::ContactEmail.delete_all
    Rails::Contact::Contact.delete_all
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear
    ActiveJob::Base.queue_adapter.performed_jobs.clear
  end
end
