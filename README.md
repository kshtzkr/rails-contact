# rails-contact

Google-shaped contacts for Rails: contact CRUD, Elasticsearch-backed search, and optional capped Google Contacts sync.

[![Gem Version](https://img.shields.io/gem/v/rails-contact.svg)](https://rubygems.org/gems/rails-contact)
[![CI](https://github.com/kshtzkr/rails-contact/actions/workflows/ci.yml/badge.svg)](https://github.com/kshtzkr/rails-contact/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](MIT-LICENSE)
[![Ruby](https://img.shields.io/badge/ruby-%3E%3D%203.1-cc342d.svg)](https://www.ruby-lang.org)

`rails-contact` is a mountable Rails engine that adds a contacts section to a host
application. It models contacts the way Google Contacts does: rich name fields plus
many emails, phones, addresses, websites, and events per person, with labels and a
free-form `metadata` JSON column for host-specific data. Search runs through
Elasticsearch and falls back to a plain SQL query when Elasticsearch is unavailable.
An optional feature pushes contacts to Google Contacts through the People API, bounded
by a configurable cap so a large table never syncs unbounded.

## Contents

- [Requirements](#requirements)
- [Installation](#installation)
- [Names and namespaces](#names-and-namespaces)
- [Quick start](#quick-start)
- [Usage](#usage)
  - [Contacts and the UI](#contacts-and-the-ui)
  - [Search](#search)
  - [Google Contacts sync](#google-contacts-sync)
  - [Merge and bulk delete](#merge-and-bulk-delete)
  - [Metadata filters and sorts](#metadata-filters-and-sorts)
  - [Host layout and asset injection](#host-layout-and-asset-injection)
- [Configuration](#configuration)
- [Generators](#generators)
- [Rake tasks](#rake-tasks)
- [Routes](#routes)
- [Testing](#testing)
- [Development](#development)
- [Releasing](#releasing)
- [Contributing](#contributing)
- [Security](#security)
- [Versioning and changelog](#versioning-and-changelog)
- [Related docs](#related-docs)
- [License](#license)

## Requirements

- Ruby >= 3.1
- Rails >= 7.1 (this is a mountable engine; it runs inside a host Rails app)
- PostgreSQL for the host database. The database search backend uses PostgreSQL
  JSON operators (`metadata->>'key'`) and a regex cast for numeric metadata; the
  test suite runs on SQLite, which the backend also handles.
- Elasticsearch 8.13+ if you use the default `:elasticsearch` search backend. It
  is optional: set `search_backend = :database` to skip it, and even with the
  Elasticsearch backend selected, search falls back to SQL when the cluster is
  unreachable.
- A Google OAuth access token with People API access if you enable Google sync
  (see [Google Contacts sync](#google-contacts-sync)).

## Installation

Add the gem to the host application's `Gemfile`:

```ruby
gem "rails-contact"
```

Install it:

```bash
bundle install
```

Generate the initializer, migrations, and route mount, then migrate:

```bash
rails generate rails:contact:contact Contact
rails db:migrate
```

`rails:contact:contact` invokes the install generator (which writes
`config/initializers/rails_contact.rb` and mounts the engine) and copies the eight
migrations for contacts and their associated tables. See [Generators](#generators)
for the individual generators if you want finer control.

## Names and namespaces

The gem name and the code namespace differ, which trips up most first installs:

| What | Value |
|---|---|
| Gem name (Gemfile, RubyGems) | `rails-contact` |
| Require path | `rails/contact` (`require "rails/contact"`) |
| Ruby namespace | `Rails::Contact` |
| Engine class | `Rails::Contact::Engine` |
| Generator namespace | `rails:contact:*` |

Bundler auto-requires the gem, so a plain `gem "rails-contact"` is enough — you do
not normally call `require` yourself. If you do, the path is `rails/contact`, not
`rails-contact` or `rails_contact`. Configuration and models live under the
`Rails::Contact` namespace.

## Quick start

After installing (above), the engine is mounted at `/contacts`. Start the app and
visit:

- `/contacts` — searchable, paginated list
- `/contacts/new` — create form with dynamic add/remove rows
- `/contacts/:id` — contact detail

Create a contact in code:

```ruby
contact = Rails::Contact::Contact.create!(
  given_name: "Ada",
  family_name: "Lovelace",
  emails_attributes: [{ value: "ada@example.com", label: "work", primary: true }],
  phones_attributes: [{ value: "+1 555 0100", label: "mobile" }]
)

contact.full_name       # => "Ada Lovelace"
contact.primary_email    # => the primary ContactEmail
contact.set_labels_from_csv!("vip, investor")
```

`given_name` is the only required field. Search the index the UI uses:

```ruby
result = Rails::Contact::Search::Query.new("ada", page: 1).call
result.records      # => [contact, ...]
result.total_count  # => 1
result.total_pages  # => 1
```

## Usage

### Contacts and the UI

`Rails::Contact::Contact` has the scalar fields `given_name`, `family_name`,
`current_city`, `departure_city`, `region_name`, `biography`, `starred`,
`sync_eligible`, `photo_url`, and a `metadata` JSON column. It has many `emails`,
`phones`, `addresses`, `websites`, `events`, and `labels`. Nested attributes are
accepted for the first five, with `allow_destroy: true`, so the generated form can
add and remove rows client-side.

The mounted controller (`Rails::Contact::ContactsController`) serves the standard
seven actions plus `bulk_destroy`, `merge`, `google_sync_unsynced`, and
`google_sync_rolling_window`. Creating, updating, or deleting a contact enqueues
`Rails::Contact::IndexContactJob` to keep the Elasticsearch index current.

Only a fixed set of `metadata` keys is accepted through the form:
`prefix`, `middle_name`, `suffix`, `nickname`, `company`, `job_title`, `department`,
`website`, `birthday`, `notes`. Read them back with `contact.meta(:company)`.

### Search

`Rails::Contact::Search::Query` is the entry point the index action uses. It picks a
backend from `config.search_backend`, runs the query, and returns a
`Rails::Contact::Search::Result` (a struct of `records`, `total_count`, `page`,
`per_page`, and a derived `total_pages`).

```ruby
Rails::Contact::Search::Query.new(
  "lovelace",
  filters: { "city" => "London", "starred" => true },
  page: 1,
  per_page: 25
).call
```

`per_page` defaults to `config.default_per_page` and is capped at 100.

Two backends implement the same `search(query, filters, page:, per_page:)` contract:

- **Elasticsearch** (`config.search_backend = :elasticsearch`, the default). Queries
  the `rails_contact_contacts` index with a fuzzy `multi_match` over name, emails,
  phone (E.164), company, job title, and labels. If any Elasticsearch call raises,
  it falls back to the database backend for that request. Supported filters: `city`,
  `region`, `starred`, `sync_eligible` (city and region accept an array for
  multi-select). Metadata filters and sorts are ignored by this backend.
- **Database** (`config.search_backend = :database`, or any other value). Runs a
  `LIKE` query over name, `metadata` company/job title, email value, phone E.164, and
  label name. The query string is sanitized internally — `LIKE` metacharacters
  (`% _ \`) are escaped and input is capped at 200 characters — so a user typing `%`
  cannot widen the match to every row. This backend also supports the date-range,
  `csv_import_id`, and configured metadata filters and sorts (see below).

Keep the Elasticsearch index in sync with the rake task:

```bash
rake rails_contact:reindex
```

It creates the index if needed and reindexes every contact.

### Google Contacts sync

Sync is off by default. It pushes local contacts to Google Contacts through the
People API (`https://people.googleapis.com/v1`): new contacts are created, contacts
already linked to a Google record are updated, and Google's `resourceName` and `etag`
are stored back on the contact so later updates target the right remote record.

Enable it and provide credentials in `config/initializers/rails_contact.rb`:

```ruby
Rails::Contact.configure do |config|
  config.google_sync_enabled = true
  config.google_max_contacts = 25_000
  config.google_token_path   = "tmp/rails_contact_google_token.json"
end
```

Authentication uses an OAuth access token, not the client credentials directly. The
engine reads the token from a JSON file at `google_token_path`:

```json
{ "access_token": "ya29...." }
```

Your host application is responsible for the OAuth flow (request a scope such as
`https://www.googleapis.com/auth/contacts`) and for writing that file. The
`google_client_id`, `google_client_secret`, and `google_redirect_uri` settings are
provided as a place to keep those values for your own flow; the engine itself does
not consume them. `Rails::Contact::Google::TokenStore#write!(payload)` is available
to persist the token JSON once you have it. The engine adds
`google_access_token`, `google_refresh_token`, and `authorization` to Rails'
filtered parameters so tokens do not appear in logs.

**The cap.** `google_max_contacts` (default 25,000) bounds a rolling-window sync.
`Contact.sync_window` is `recent_first.limit(google_max_contacts)`, ordered by
`updated_at` then `id` descending, so a rolling sync only ever pushes the most
recently updated N contacts. Contacts that fall outside that window are not touched
by the rolling job.

Two operations exist:

| Operation | Job | Scope |
|---|---|---|
| Rolling window | `GoogleSyncJob` (`SyncService#sync!`) | the newest `google_max_contacts` contacts (create + update) |
| Unsynced only | `GoogleSyncUnsyncedJob` (`SyncService#sync_unsynced!`) | contacts with no `google_resource_name`, in batches of 100, uncapped |

Trigger them from the UI (the buttons on the index, when sync is enabled), by
enqueuing the jobs, or through rake:

```bash
rake rails_contact:sync_google   # runs GoogleSyncJob.perform_now
```

The index action posts to `google_sync_rolling_window_contacts_path` and
`google_sync_unsynced_contacts_path`, which enqueue the two jobs. Both the controller
actions and the jobs no-op unless `google_sync_enabled` is true.

### Merge and bulk delete

`POST /merge` with `source_id` and `target_id` runs
`Rails::Contact::MergeContactsService`, which folds the source contact into the
target inside a transaction: scalar fields fill blanks on the target, nested records
(emails, phones, addresses, websites, events) are copied when not already present,
labels are unioned, metadata is merged (target wins on key conflicts), and the source
is destroyed. Merging a contact into itself raises.

`POST /bulk_destroy` with a comma-separated `ids` param deletes the selected contacts.

### Metadata filters and sorts

Contacts carry app-specific values in the `metadata` JSON column. You declare which
keys are filterable and sortable, and the engine permits the params, normalizes
multi-selects, guards the SQL, and applies the filter (database backend only):

```ruby
Rails::Contact.configure do |config|
  config.metadata_filters = {
    "tier"      => { key: "quality_tier", type: :values, allowed: %w[hot warm standard] },
    "min_pax"   => { key: "pax",          type: :min_integer },
    "min_score" => { key: "score",        type: :min_numeric },
    "vip"       => { key: "tags",         type: :tag, tag: "vip" }
  }
  config.metadata_sorts = {
    "score" => { key: "score" }  # ?sort=score orders by metadata score, highest first
  }
end
```

The filter types and the rules that guard them are described in full in
[docs/CONFIGURATION.md](docs/CONFIGURATION.md#metadata-filters-and-sorts).

### Host layout and asset injection

By default the engine renders its pages inside the host layout named `application`, so
contacts pages match the rest of the app (Turbo and importmap included). Engine CSS is
pulled into each view with `stylesheet_link_tag`, and the add-row and bulk-selection
behavior runs from small inline scripts, so you do not have to pin gem JavaScript in
the host importmap.

To use the engine's own layout and its bundled
`javascript_include_tag "rails/contact/application"` instead:

```ruby
Rails::Contact.configure do |config|
  config.inherit_host_layout = false
end
```

## Configuration

The install generator writes `config/initializers/rails_contact.rb`. Every setting has
a default, so the initializer only needs the ones you change. The commonly used
settings:

```ruby
Rails::Contact.configure do |config|
  config.search_backend    = :elasticsearch
  config.elasticsearch_url  = ENV.fetch("ELASTICSEARCH_URL", "http://127.0.0.1:9200")
  config.default_per_page   = 25
  config.inherit_host_layout = true

  config.google_sync_enabled = false
  config.google_max_contacts = 25_000
  config.google_token_path   = "tmp/rails_contact_google_token.json"
end
```

The full reference — every setting, its type, default, backing environment variable,
and what it does — is in [docs/CONFIGURATION.md](docs/CONFIGURATION.md).

## Generators

```bash
rails generate rails:contact:install      # initializer + engine mount
rails generate rails:contact:contact NAME # invokes install, then copies migrations
rails generate rails:contact:controllers  # copy an override-ready contacts controller
```

- `install` writes `config/initializers/rails_contact.rb` and adds
  `mount Rails::Contact::Engine => '/contacts', as: 'rails_contact'` to your routes.
- `contact` runs `install` and copies the eight migrations (contacts, emails, phones,
  addresses, websites, events, labels, contact_labels).
- `controllers` copies an override-ready contacts controller into the host app so you
  can customize it, Devise-style.

A `rails:contact:views` generator is also defined, but it currently copies from
`app/views/rails/contact/contacts`, a directory the engine no longer uses (its views
live directly under `app/views/rails/contact`), so it does not copy the current
templates. To customize views today, copy the files from
`app/views/rails/contact/` in the gem into the same path in your app.

## Rake tasks

```bash
rake rails_contact:reindex      # create the Elasticsearch index and reindex all contacts
rake rails_contact:sync_google  # run GoogleSyncJob.perform_now (rolling-window sync)
rake rails_contact:install      # prints the install generator command
```

## Routes

Mounting adds these routes under the mount path (`/contacts` by default):

| Method | Path | Action |
|---|---|---|
| GET | `/` | `index` |
| GET | `/new` | `new` |
| POST | `/` | `create` |
| GET | `/:id` | `show` |
| GET | `/:id/edit` | `edit` |
| PATCH/PUT | `/:id` | `update` |
| DELETE | `/:id` | `destroy` |
| POST | `/bulk_destroy` | `bulk_destroy` |
| POST | `/merge` | `merge` |
| POST | `/google_sync_unsynced` | `google_sync_unsynced` |
| POST | `/google_sync_rolling_window` | `google_sync_rolling_window` |

You can mount explicitly or use the routing helper, which normalizes a singular or
plural resource name to the plural path:

```ruby
# config/routes.rb
mount Rails::Contact::Engine => "/contacts", as: "rails_contact"
# or, equivalently:
rails_contact_for :contacts   # rails_contact_for :contact also mounts at /contacts
```

`rails_contact_for` accepts an `at:` path and an `as:` name if you want to override
the defaults.

## Testing

The suite is RSpec, with SimpleCov enforcing line and branch coverage in CI:

```bash
bundle exec rspec
```

CI (`.github/workflows/ci.yml`) runs RuboCop and the specs against Ruby 3.2 and 3.3
with an Elasticsearch 8.13 service. A smaller Minitest suite under `test/` covers the
Google client and sync service.

## Development

```bash
git clone https://github.com/kshtzkr/rails-contact.git
cd rails-contact
bundle install
bundle exec rspec        # run the tests
bin/rubocop              # lint
```

## Releasing

Releases go to RubyGems with the standard Bundler gem tasks:

```bash
bundle exec rake build
bundle exec rake release
```

RubyGems MFA is required to push (`rubygems_mfa_required` is set in the gemspec).

## Contributing

Bug reports and pull requests are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for
setup, the branch and PR flow, and the commit-message convention. This project follows
the [Contributor Covenant](CODE_OF_CONDUCT.md) code of conduct.

## Security

Please report security issues privately rather than opening a public issue. See
[SECURITY.md](SECURITY.md).

## Versioning and changelog

`rails-contact` follows [Semantic Versioning](https://semver.org). Notable changes are
recorded in [CHANGELOG.md](CHANGELOG.md).

## Related docs

- [docs/CONFIGURATION.md](docs/CONFIGURATION.md) — full configuration reference
- [docs/migration_guide.md](docs/migration_guide.md) — upgrading across the breaking rewrite
- [docs/parity_matrix.md](docs/parity_matrix.md) — feature parity against Google Contacts
- [docs/product_decisions.md](docs/product_decisions.md) — design decisions
- [docs/roadmap.md](docs/roadmap.md) — planned work

## License

Released under the [MIT License](MIT-LICENSE).
