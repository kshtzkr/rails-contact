# Product Decisions

## Rewrite mode

- Breaking rewrite is allowed.
- Existing internals can be replaced to improve parity and maintainability.

## Source of truth

- Postgres remains canonical store.
- Elasticsearch remains derived search index.
- Google Contacts remains bounded mirror for rolling sync window.

## UI approach

- Tailwind-compatible semantic ERB views.
- Hotwire + Stimulus patterns for dynamic nested field rows.
- Devise-style override generators (`views`, `controllers`).

## Data model approach

- Keep normalized multi-value tables for core fields.
- Use `metadata` JSON for extensible fields not requiring immediate indexing.
- Add explicit label/event/website entities for high-value searchable features.

## Sync policy

- Two-way sync on rolling window.
- Default conflict policy: last-write-wins with timestamp + ETag awareness.
- Deterministic merge behavior with audit-friendly outcomes.

## Quality policy

- RSpec is mandatory.
- Coverage target is 100% line and 100% branch in CI.
- PRs fail if quality thresholds regress.
