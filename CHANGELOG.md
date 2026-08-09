# Changelog

## 0.1.17

- **Database backend free-text search is now prefix search.** `q` matches
  `LOWER(col) LIKE 'q%'` instead of `'%q%'`, so a plain btree
  (`text_pattern_ops` on PostgreSQL) can serve every arm — the substring form
  could use no index and forced a full scan of a 3-way-joined, `DISTINCT`ed
  row set on multi-million-row tables. Match arms (given/family name, company,
  job title, email, phone, label) run as a `UNION` of id-subqueries rather
  than one `OR`, letting the planner drive each arm from its own index. Phone
  input matches with and without the e164 `+`, so typing bare digits still
  works. Trade-off: mid-string fragments no longer match ("`ave`" no longer
  finds "Dave") — matching how operators actually hunt (start of a name,
  email, or number).
- **Large result counts use the PostgreSQL planner estimate.** Exact
  `COUNT(*)` walks every matching row on every page load; results at or above
  1,000 rows now take the row estimate from `EXPLAIN (FORMAT JSON)`
  (milliseconds at any table size), while smaller results keep exact counts.
  Non-PostgreSQL adapters and planner failures fall back to exact counting.
  Estimates are display-only — never feed `total_count` into arithmetic.

## 0.1.16

- **New metadata filter type `:exclude`** — hides rows whose metadata key equals a configured value, e.g. `{ key: "authenticity", type: :exclude, value: "test", default: :on }`. With `default: :on` the filter applies even when the request param is absent (first page load, bookmarks) and an explicit false-y value (`"0"`) switches it off — built for default-on "hide test data" checkboxes. Rows missing the key always pass, so unclassified legacy data is never hidden.

## [Unreleased]

### Documentation

- Rewrote the README with a badge row, table of contents, requirements, a
  gem-name/require/namespace note, and usage sections for search, Google sync,
  merge, and metadata filters.
- Added `docs/CONFIGURATION.md` with the full settings reference (type, default,
  environment variable, and behavior for every configuration option).
- Added `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, and `SECURITY.md`.
- Removed the duplicate `LICENSE.txt` (identical to `MIT-LICENSE`) and dropped it
  from the gemspec file list; removed committed `.gem` build artifacts.

## 0.1.15

- **Host-configurable metadata filters and sorts.** `config.metadata_filters` declares filters over `Contact#metadata` by param name — `:values` (multi-select with optional whitelist), `:min_integer` / `:min_numeric` (numeric floors that filter out non-numeric stored values instead of casting them), and `:tag` (JSON-array containment checkbox). `config.metadata_sorts` declares `?sort=` options over numeric metadata (descending, non-numeric last, recency tiebreak). `filter_params` permits the configured params automatically, multi-selects get the same blank-strip/scalar-coercion normalization as `region`, and a metadata sort is dropped while a free-text `q` search is active (the search branch runs `SELECT DISTINCT`, which PostgreSQL cannot order by an out-of-select expression). Database backend only. Configured keys must be plain identifiers; anything else raises.

## 0.1.14

- Contacts index filters: **`region` and `csv_import_id` are now multi-select**. `filter_params` permits `region: []` / `csv_import_id: []`, strips the hidden blank a `<select multiple>` submits, and coerces a legacy scalar (`?region=Europe`) to a one-element array. The database backend matches `metadata->>'csv_import_id' IN (...)` across the selected imports (a single id behaves exactly as before); `region` was already array-safe via `where(region_name:)`.
- Database backend: **search query is now sanitized internally** — LIKE metacharacters (`% _ \`) are escaped and input is capped at 200 chars, so a user typing `%` can no longer widen the match to every row. Host apps no longer need to wrap `search` to be safe.

## 0.1.12

- `_google_sync_panel`: render the card whenever `google_sync_ui_on_index`; if `google_sync_enabled` is false, show short instructions instead of hiding the section entirely.

## 0.1.11

- Default **Google sync panel** back on the engine index via `_google_sync_panel` when `google_sync_enabled` and `google_sync_ui_on_index` (default true). Host apps can override the partial or disable with `google_sync_ui_on_index = false`.

## 0.1.10

- Short-lived: engine index omitted the Google panel (use **0.1.11** instead).

## 0.1.9

- `POST /google_sync_rolling_window` → `ContactsController#google_sync_rolling_window` → `GoogleSyncJob` (re-sync rolling window: creates + updates).

## 0.1.8

- Contacts index: paginated search (total count, previous/next, page indicator) with Elasticsearch and database backends.
- `POST /google_sync_unsynced` and **Sync … not yet in Google** button when sync is enabled; `GoogleSyncUnsyncedJob` runs `SyncService#sync_unsynced!` for contacts with no `google_resource_name`.

## 0.1.7

- Google People API: `updateContact` sends required `updatePersonFields`; update payloads include `resourceName` and `etag`; sync preloads emails, phones, and addresses.
- Google: optional `google_contact_family_name_suffix` (and env `RAILS_CONTACT_GOOGLE_CONTACT_FAMILY_NAME_SUFFIX`) for family name in sync payloads only.
- Google: payload mapper skips blank emails/phones, omits empty association arrays, biography uses `TEXT_PLAIN` when present.
- Elasticsearch search backend reuses one `Elasticsearch::Client` per process (fewer product-check warnings).
- Remove CSV import from the gem (keep imports in the host application). Drops `rails_contact:import_csv` and `Csv::ImportService`.
- Engine registers stylesheet/javascript paths for Propshaft.

## 0.1.5

- Scope engine stylesheet to contacts content only (`.rails-contact-page`) so host app layout/header styling is not overridden.
- Add missing utility shims (`block`, `flex-wrap`, `text-base`, `mt-7`) used by contact templates for consistent spacing/labels.

## 0.1.4

- Default to the host `application` layout when the engine is mounted, with `inherit_host_layout` (default `true`) to opt back into the engine-only layout.
- Ensure nested field add/remove and bulk checkbox scripts run when the host uses importmap (inline scripts + idempotent global guards; same guard in `nested_fields.js` for the Sprockets bundle).
- Pull engine stylesheet into each main contact view so styling works without the engine layout’s asset tags.

## 0.1.3

- Flatten view partial paths under `app/views/rails/contact` and remove legacy `contacts/` partial nesting.
- Add `.gitignore` to keep generated artifacts (including `coverage/`) out of release commits.
- Update packaging/docs metadata for smoother RubyGems release workflow.

## 0.1.2

- Breaking parity-focused rewrite foundation for richer Google-like contacts.
- Added label, website, event, merge, and bulk-delete capabilities.
- Added dynamic nested field add/remove behavior for multi-value rows.
- Introduced RSpec suite with SimpleCov gates (100% line/branch in tracked critical files).
- Added parity matrix, roadmap, and migration documentation.

## 0.1.1

- Fix mounted route shape to avoid `/contacts/contacts` duplication.
- Improve README quick-start and generator documentation.
- Add controller override generator (`rails generate rails:contact:controllers`).
- CI/test command hardening and Ruby 3.2 dependency compatibility fixes.

## 0.1.0

- Initial release of `rails-contact`.
- Mountable engine with contact CRUD.
- CSV import service for Google-shaped contact fields.
- Elasticsearch-backed search with database fallback.
- Google Contacts sync service scaffold with rolling-window support.
- Generators for install and migrations.
