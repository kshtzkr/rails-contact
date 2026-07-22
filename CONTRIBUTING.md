# Contributing

Thanks for taking the time to contribute to `rails-contact`. Bug reports, fixes, and
documentation improvements are all welcome.

## Getting set up

```bash
git clone https://github.com/kshtzkr/rails-contact.git
cd rails-contact
bundle install
```

Run the test suite and the linter before you push:

```bash
bundle exec rspec
bin/rubocop
```

The specs run on SQLite and do not need Elasticsearch. Coverage is enforced by
SimpleCov, so keep new code covered.

## Reporting bugs

Open an issue at https://github.com/kshtzkr/rails-contact/issues. Include the gem
version, Ruby and Rails versions, what you expected, what happened, and a minimal
reproduction if you can.

For security issues, do not open a public issue — see [SECURITY.md](SECURITY.md).

## Pull requests

1. Branch off `main`.
2. Make one logical change per pull request. Add or update specs for behavior changes.
3. Run `bundle exec rspec` and `bin/rubocop` locally; CI runs both and must pass.
4. Push your branch and open a pull request against `main` with a clear description of
   the change and why.

## Commit messages

This project uses [Conventional Commits](https://www.conventionalcommits.org): a
`type(scope): summary` subject line, for example `fix(search): escape LIKE
metacharacters`. Common types are `feat`, `fix`, `docs`, `refactor`, `test`, and
`chore`. Keep each commit to one logical change.

## Code of conduct

By participating you agree to the [Contributor Covenant](CODE_OF_CONDUCT.md).
