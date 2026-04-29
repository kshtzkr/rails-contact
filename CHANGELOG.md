# Changelog

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
