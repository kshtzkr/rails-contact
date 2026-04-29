# rails-contact

`rails-contact` is a mountable Rails engine for Google-shaped contact management with:

- local source-of-truth data model
- Elasticsearch-powered search/filter (with DB fallback)
- CSV import pipeline
- capped rolling-window Google Contacts sync hooks

## Install

```ruby
gem "rails-contact"
```

```bash
bundle install
rails generate rails:contact:install
rails generate rails:contact:contact Contact
rails db:migrate
```

## Configure

Initializer: `config/initializers/rails_contact.rb`

```ruby
Rails::Contact.configure do |config|
  config.search_backend = :elasticsearch
  config.elasticsearch_url = ENV.fetch("ELASTICSEARCH_URL", "http://127.0.0.1:9200")
  config.google_sync_enabled = true
  config.google_max_contacts = 25_000
  config.rolling_window_sort = :updated_at
end
```

## Mount

```ruby
mount Rails::Contact::Engine => "/contacts", as: "rails_contact"
```

## Features

- Contact CRUD with nested emails/phones/addresses
- Filter and full-text search by name, email, and phone
- CSV import mapping for fields like Enquirer First Name / Enquirer Email / country-code phones
- Google payload mapping and sync service scaffolding
- Reindex and sync tasks:
  - `rake rails_contact:reindex`
  - `rake rails_contact:sync_google`
  - `rake rails_contact:import_csv CSV_PATH=/path/to/file.csv`

## Test

```bash
bundle exec ruby -Itest test/**/*_test.rb
```

## Release

```bash
bundle exec rake build
bundle exec rake release
```

Ensure RubyGems MFA is enabled for maintainers.

## License

MIT.
