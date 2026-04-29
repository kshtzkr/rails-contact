# Changelog

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
