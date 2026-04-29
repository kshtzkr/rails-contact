require_relative "lib/rails/contact/version"

Gem::Specification.new do |spec|
  spec.name = "rails-contact"
  spec.version = Rails::Contact::VERSION
  spec.authors = [ "Kshitiz Sinha" ]
  spec.email = [ "kshtzkr@gmail.com" ]
  spec.homepage = "https://github.com/kshtzkr/rails-contact"
  spec.summary = "Google-shaped contacts for Rails with search and sync."
  spec.description = "Mountable Rails engine offering contact CRUD, CSV import, Elasticsearch-backed search, and optional capped Google Contacts two-way sync."
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/kshtzkr/rails-contact/tree/main"
  spec.metadata["changelog_uri"] = "https://github.com/kshtzkr/rails-contact/releases"
  spec.metadata["bug_tracker_uri"] = "https://github.com/kshtzkr/rails-contact/issues"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.glob("{app,bin,config,lib,docs,spec,.github}/**/*") + %w[README.md CHANGELOG.md LICENSE.txt MIT-LICENSE Gemfile Rakefile .rspec]
  spec.require_paths = [ "lib" ]

  spec.add_dependency "rails", ">= 7.1"
  spec.add_dependency "httparty", ">= 0.22"
  spec.add_dependency "phonelib", ">= 0.8"
  spec.add_dependency "faraday", ">= 2.9"
  spec.add_dependency "faraday-retry", ">= 2.2"
  spec.add_dependency "elasticsearch", ">= 8.13"
end
