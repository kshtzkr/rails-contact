# rails-contact

`rails-contact` is a mountable Rails engine for Google-Contacts-style contact management.

It provides:

- rich contact profile fields
- multi-value contact methods (emails/phones/addresses/websites/events)
- labels/tags
- dynamic add/remove nested rows
- Elasticsearch-backed search with DB fallback
- CSV import and Google sync scaffolding
- merge and bulk-delete operations
- Devise-style override generators

---

## Quickstart

### 1) Add gem

```ruby
gem "rails-contact", "~> 0.1.4"
```

```bash
bundle install
```

### 2) Install and generate schema

```bash
rails generate rails:contact:install
rails generate rails:contact:contact Contact
rails db:migrate
```

### 3) Mount engine routes

```ruby
rails_contact_for :contacts
```

or explicit mount:

```ruby
mount Rails::Contact::Engine => "/contacts", as: "rails_contact"
```

`rails_contact_for :contact` is auto-normalized to `/contacts`.

### 4) Visit UI

- `/contacts`
- `/contacts/new`
- `/contacts/:id`

### Host layout and importmap

By default the engine uses your host app layout named `application` so contacts pages match the rest of your UI (including Turbo and importmap). Styles for engine markup are included per page via `stylesheet_link_tag`, and nested “add row” / bulk-selection behavior uses small inline scripts so you do **not** need to pin gem JavaScript in the host importmap.

To use the engine’s standalone layout and bundled `javascript_include_tag "rails/contact/application"` instead:

```ruby
Rails::Contact.configure do |config|
  config.inherit_host_layout = false
end
```

---

## Generators

```bash
rails generate rails:contact:install
rails generate rails:contact:contact Contact
rails generate rails:contact:views
rails generate rails:contact:controllers
```

- `views` copies templates so host apps can customize UI.
- `controllers` copies an override-ready contacts controller.

---

## Feature map

### Core profile fields

- Prefix, first, middle, last, suffix, nickname
- Company, job title, department
- Labels (comma-separated input)
- Notes and metadata
- Starred flag
- Photo URL

### Multi-value sections (dynamic)

- Emails
- Phones
- Addresses
- Websites
- Events (birthday/custom)

Rows can be added/removed dynamically in form UI.

### List/search

- Search by name/email/phone/company/job title/labels
- Filter by city/region/sync/starred
- Sort by recent updates

### Actions

- Bulk delete selected contacts
- Merge source contact into target contact

---

## Configuration

Initializer: `config/initializers/rails_contact.rb`

```ruby
Rails::Contact.configure do |config|
  config.search_backend = :elasticsearch
  config.elasticsearch_url = ENV.fetch("ELASTICSEARCH_URL", "http://127.0.0.1:9200")
  config.google_sync_enabled = false
  config.google_max_contacts = 25_000
  config.rolling_window_sort = :updated_at
  config.default_per_page = 25
end
```

---

## Rake tasks

```bash
rake rails_contact:reindex
rake rails_contact:sync_google
rake rails_contact:import_csv CSV_PATH=/absolute/path/to/eq.csv
```

---

## Testing and coverage

RSpec is the primary framework.

```bash
bundle exec rspec
```

Coverage is enforced with SimpleCov:

- 100% line coverage target
- 100% branch coverage target
- CI fails below thresholds

---

## Release

```bash
bundle exec rake build
bundle exec rake release
```

RubyGems MFA is required for push.

---

## Extended docs

- `docs/parity_matrix.md`
- `docs/product_decisions.md`
- `docs/roadmap.md`
- `docs/migration_guide.md`
