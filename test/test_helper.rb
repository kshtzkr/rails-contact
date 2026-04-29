ENV["RAILS_ENV"] ||= "test"

require "bundler/setup"
require "rails"
require "active_record"
require "active_job"
require "minitest/autorun"
require "minitest/reporters"
require "webmock/minitest"
require "mocha/minitest"
require "rails/contact"

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

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
    t.datetime :google_last_modified_at
    t.datetime :last_synced_at
    t.boolean :sync_eligible, default: true
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
end

ActiveJob::Base.queue_adapter = :test
