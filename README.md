# rails-contact

`rails-contact` is a mountable Rails engine to manage contacts in your app, with optional Elasticsearch search and Google Contacts sync.

## What you get

- Contact CRUD screens and controller
- Local contact schema (emails, phones, addresses)
- CSV importer
- Elasticsearch search backend (with DB fallback)
- Google sync service scaffolding
- Install, migration, view, and controller generators

## 1) Install the gem

```ruby
gem "rails-contact"
```

```bash
bundle install
```

## 2) Run generators

```bash
rails generate rails:contact:install
rails generate rails:contact:contact Contact
```

Optional override generators (Devise-style customization):

```bash
rails generate rails:contact:views
rails generate rails:contact:controllers
```

Then migrate:

```bash
rails db:migrate
```

## 3) Mount routes (clean paths)

Use either:

```ruby
mount Rails::Contact::Engine => "/contacts", as: "rails_contact"
```

or:

```ruby
rails_contact_for :contacts
```

With this setup, paths are:
- `/contacts` (index)
- `/contacts/new`
- `/contacts/:id`

No `/contacts/contacts` duplication.

## 4) Configure

Generated initializer: `config/initializers/rails_contact.rb`

```ruby
Rails::Contact.configure do |config|
  config.search_backend = :elasticsearch
  config.elasticsearch_url = ENV.fetch("ELASTICSEARCH_URL", "http://127.0.0.1:9200")
  config.google_sync_enabled = false
  config.google_max_contacts = 25_000
  config.rolling_window_sort = :updated_at
end
```

## CSV import

```bash
rake rails_contact:import_csv CSV_PATH=/absolute/path/to/eq.csv
```

## Utility tasks

- `rake rails_contact:reindex`
- `rake rails_contact:sync_google`

## Test

```bash
bundle exec ruby -Itest -e 'Dir["test/**/*_test.rb"].sort.each { |f| require File.expand_path(f) }'
```

## Release

```bash
bundle exec rake build
bundle exec rake release
```

RubyGems MFA is required.
