# Migration Guide (Breaking Rewrite)

This release introduces a breaking rewrite for parity-focused contact management.

## Key changes

- Expanded schema for labels, websites, and events.
- Richer metadata contract in forms and controllers.
- New bulk actions (`bulk_destroy`) and merge endpoint.
- Dynamic nested row UI behavior in contact form.
- RSpec + SimpleCov quality gates.

## Required host steps

1. Update gem version in host `Gemfile`.
2. Re-run generator migration tasks:
   - `rails generate rails:contact:contact Contact`
3. Run migrations:
   - `rails db:migrate`
4. If you copied views/controllers previously, regenerate and re-merge:
   - `rails generate rails:contact:views`
   - `rails generate rails:contact:controllers`

## Route mounting

Use:

```ruby
rails_contact_for :contacts
```

or explicit:

```ruby
mount Rails::Contact::Engine => "/contacts", as: "rails_contact"
```

## Verification checklist

- Contacts list renders with advanced columns.
- Create/edit form supports dynamic add/remove entries.
- Labels persist and display.
- Merge and bulk delete actions work as expected.
- RSpec and lint are green.
