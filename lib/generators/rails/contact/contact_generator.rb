require "rails/generators"
require "rails/generators/active_record"

module Rails
  module Contact
    module Generators
      class ContactGenerator < ::Rails::Generators::NamedBase
        include ::Rails::Generators::Migration

        source_root File.expand_path("templates", __dir__)

        def self.next_migration_number(dirname)
          ActiveRecord::Generators::Base.next_migration_number(dirname)
        end

        def create_initializer
          invoke "rails:contact:install"
        end

        def copy_migrations
          migration_template "create_rails_contact_contacts.rb.tt", "db/migrate/create_rails_contact_contacts.rb"
          migration_template "create_rails_contact_contact_emails.rb.tt", "db/migrate/create_rails_contact_contact_emails.rb"
          migration_template "create_rails_contact_contact_phones.rb.tt", "db/migrate/create_rails_contact_contact_phones.rb"
          migration_template "create_rails_contact_contact_addresses.rb.tt", "db/migrate/create_rails_contact_contact_addresses.rb"
        end
      end
    end
  end
end
