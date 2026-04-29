require_relative "lib/rails/contact/version"

Gem::Specification.new do |spec|
  spec.name        = "rails-contact"
  spec.version     = Rails::Contact::VERSION
  spec.authors     = [ "Kshitiz Sinha" ]
  spec.email       = [ "kshtzkr@gmail.com" ]
  spec.homepage    = "https://rubygems.org/gems/rails-contact"
  spec.summary     = "Google-shaped contacts for Rails with search and sync."
  spec.description = "Mountable Rails engine offering contact CRUD, CSV import, Elasticsearch-backed search, and optional capped Google Contacts two-way sync."
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/example/rails-contact"
  spec.metadata["changelog_uri"] = "https://github.com/example/rails-contact/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib,test}/**/*", ".github/workflows/ci.yml", "MIT-LICENSE", "Rakefile", "README.md", "CHANGELOG.md"]
  end

  spec.add_dependency "rails", ">= 7.1"
  spec.add_dependency "httparty", ">= 0.22"
  spec.add_dependency "phonelib", ">= 0.8"
  spec.add_dependency "faraday", ">= 2.9"
  spec.add_dependency "faraday-retry", ">= 2.2"
  spec.add_dependency "elasticsearch", ">= 8.13"
end
