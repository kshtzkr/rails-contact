# Google Contacts Parity Matrix

This matrix tracks feature parity for `rails-contact` versus Google Contacts.

## Legend

- `P0` = immediate implementation in rewrite
- `P1` = advanced implementation in next wave
- `P2` = roadmap / heuristic-heavy behaviors

## Create/Edit Contact

| Capability | Google Contacts | rails-contact Target | Priority | Acceptance Criteria |
|---|---|---|---|---|
| Rich name fields | Prefix, first, middle, last, suffix, nickname | Same | P0 | Form supports all fields and persists values |
| Multi email entries | Add/remove many emails with labels | Same | P0 | Dynamic row add/remove and primary marker works |
| Multi phone entries | Add/remove many phones with labels | Same | P0 | Dynamic row add/remove and E.164 normalization works |
| Multi addresses | Add/remove many addresses | Same | P0 | Dynamic row add/remove with label and formatted value |
| Company/title/department | Work profile fields | Same | P0 | Values editable and displayed on show/list |
| Website fields | One or more website entries | Same | P0 | Multi website rows persist correctly |
| Events (birthday, custom) | Structured event entries | Same | P0 | Birthday + custom events persist and render |
| Notes | Long-form notes | Same | P0 | Notes support multiline and display consistently |
| Contact photo | Upload/select photo | Similar | P1 | Attach/upload photo with preview and fallback avatar |
| Custom fields | User-defined fields | Similar | P1 | Key-value custom fields can be added/removed |

## List/Search

| Capability | Google Contacts | rails-contact Target | Priority | Acceptance Criteria |
|---|---|---|---|---|
| Full-text search | Name/email/phone/org | Same | P0 | Search returns expected records with ranking |
| Filtering | Labels, city, sync state, etc. | Same | P0 | Filters combinable and reflected in query params |
| Sorting | Name/recent | Same | P0 | Deterministic sorting and pagination |
| Bulk selection/actions | Multi-select and bulk ops | Similar | P1 | Bulk label and delete actions available |
| Keyboard shortcuts | Fast actions | Similar | P1 | Documented shortcut support for major actions |
| Frequent/recent heuristics | Smart surfaced contacts | Similar | P2 | Heuristic scoring service and surfaced list |

## Organization / Labels

| Capability | Google Contacts | rails-contact Target | Priority | Acceptance Criteria |
|---|---|---|---|---|
| Labels/tags | Built-in and custom labels | Same | P0 | Labels CRUD and assignment on contacts |
| Merge & fix | Duplicate suggestions and merge | Similar | P1 | Manual merge workflow with preview + audit |
| Suggested merges | Auto-suggest duplicates | Similar | P2 | Candidate list from similarity service |

## Interop / Data

| Capability | Google Contacts | rails-contact Target | Priority | Acceptance Criteria |
|---|---|---|---|---|
| CSV import | Flexible column import | Same | P0 | Mapping profile handles eq.csv fields |
| CSV export | Download contacts | Same | P1 | Export with stable headers and escaping |
| Google sync | People API sync | Similar | P0/P1 | Two-way sync for rolling window with conflict policy |
| Conflict resolution | Last write + ETag semantics | Same policy | P1 | Deterministic merge outcomes and tests |

## Quality gates

- RSpec required for model/view/controller/helper/concern/service/system coverage.
- 100% line and branch coverage threshold enforced in CI.
