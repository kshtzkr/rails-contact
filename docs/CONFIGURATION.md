# Configuration reference

Every setting on `Rails::Contact::Configuration`, with its default and what the engine
does with it. Set them in `config/initializers/rails_contact.rb`:

```ruby
Rails::Contact.configure do |config|
  config.search_backend = :database
  # ...
end
```

All settings have defaults, so you only need to list the ones you change.

## Settings

| Setting | Type | Default | Environment variable | Description |
|---|---|---|---|---|
| `contact_class_name` | String | `"Rails::Contact::Contact"` | — | Name of the contact model. Informational in the current version — the engine references `Rails::Contact::Contact` directly. |
| `elasticsearch_url` | String | `"http://127.0.0.1:9200"` | `ELASTICSEARCH_URL` | URL of the Elasticsearch cluster used by the `:elasticsearch` backend. |
| `search_backend` | Symbol | `:elasticsearch` | — | Search backend. `:elasticsearch` uses Elasticsearch (with a database fallback on error); any other value uses the database backend. |
| `default_per_page` | Integer | `25` | — | Default page size for search. Capped at 100 per request. |
| `inherit_host_layout` | Boolean | `true` | — | When `true`, engine pages render inside the host layout named `application`. When `false`, the engine uses its own layout and bundled JavaScript. |
| `google_sync_enabled` | Boolean | `false` | `RAILS_CONTACT_GOOGLE_SYNC_ENABLED` (in the generated initializer) | Master switch for Google Contacts sync. The sync controller actions and jobs no-op when `false`. |
| `google_sync_ui_on_index` | Boolean | `true` | — | When `true`, the index renders the gem's Google sync panel partial. Set `false` to supply your own UI. |
| `google_max_contacts` | Integer | `25_000` | — | Cap on the rolling-window sync. `Contact.sync_window` limits to the newest N contacts by `updated_at`. |
| `google_token_path` | String | `"tmp/rails_contact_google_token.json"` | `RAILS_CONTACT_GOOGLE_TOKEN_PATH` | Path to the JSON file holding the OAuth access token. `TokenStore` reads the `access_token` key from it. |
| `google_client_id` | String / nil | `nil` | `GOOGLE_CLIENT_ID` | OAuth client id. Host-facing: a place to keep the value for your own OAuth flow. Not consumed by the engine. |
| `google_client_secret` | String / nil | `nil` | `GOOGLE_CLIENT_SECRET` | OAuth client secret. Host-facing, not consumed by the engine. |
| `google_redirect_uri` | String / nil | `nil` | `GOOGLE_REDIRECT_URI` | OAuth redirect URI. Host-facing, not consumed by the engine. |
| `google_contact_family_name_suffix` | String / nil | `nil` | `RAILS_CONTACT_GOOGLE_CONTACT_FAMILY_NAME_SUFFIX` | Optional suffix appended to `familyName` in Google People payloads only. Not stored on the contact. Blank disables it. |
| `rolling_window_sort` | Symbol | `:updated_at` | — | Intended sort column for the rolling window. Reserved: the current `sync_window` scope orders by `updated_at, id` and does not read this setting. |
| `reset_index_on_boot` | Boolean | `false` | — | Reserved: defined but not read by the current engine. |
| `metadata_filters` | Hash | `{}` | — | Declarative filters over `Contact#metadata`. Database backend only. See below. |
| `metadata_sorts` | Hash | `{}` | — | Declarative `?sort=` options over numeric metadata. Database backend only. See below. |

Settings marked "reserved" or "not consumed by the engine" are defined on the
configuration object and safe to set, but the current release does not act on them.
They are documented here for completeness.

## Metadata filters and sorts

Contacts carry app-specific values in the `metadata` JSON column. `metadata_filters`
and `metadata_sorts` let the host decide which keys are filterable and sortable. The
engine then permits the request params, normalizes multi-selects, guards the SQL, and
applies the filter. These apply to the **database backend only**; the Elasticsearch
backend ignores them.

```ruby
Rails::Contact.configure do |config|
  config.metadata_filters = {
    # request param name => filter declaration
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

`key:` is the metadata key to read. It is declared in code, never taken from a request
param, and must be a plain identifier matching `[a-zA-Z0-9_]+` — anything else raises,
as a guard against interpolating an unsafe fragment into SQL.

### Filter types

- `:values` — multi-select. Matches when `metadata->>key` equals any selected value.
  An optional `allowed:` whitelist discards anything outside it. A scalar param (a
  legacy bookmark such as `?tier=hot`) is coerced to a one-element selection.
- `:min_integer` / `:min_numeric` — numeric floor. Stored values that are not numbers
  are filtered out rather than cast, so an imported `"TBD"` cannot raise. `:min_numeric`
  also accepts decimals.
- `:tag` — checkbox. Matches when the metadata key (a JSON array) contains `tag:`. The
  param value `"1"` switches it on.
- `:exclude` — hides rows whose key equals `value:`. Add `default: :on` to apply the
  filter even when the request param is absent (first page load, bookmarks); an
  explicit `"0"` shows everything — built for default-on "hide test data" checkboxes.
  Rows missing the key always pass, so unclassified data is never hidden.

### Sorts

A metadata sort orders descending, puts non-numeric or missing values last, and breaks
ties by recency. Only sorts declared in `metadata_sorts` apply — an unknown `?sort=`
value is ignored.

A metadata sort is dropped while a free-text `q` search is active. The search branch
runs `SELECT DISTINCT`, and PostgreSQL rejects ordering by an expression that is not in
the select list, so search results keep recency order.
