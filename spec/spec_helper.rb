require "simplecov"

SimpleCov.start do
  enable_coverage :branch
  tracked = %w[
    /app/controllers/concerns/rails/contact/filterable.rb
    /app/helpers/rails/contact/application_helper.rb
    /app/models/rails/contact/contact.rb
  ]
  add_filter do |source_file|
    tracked.none? { |file| source_file.filename.end_with?(file) }
  end
  minimum_coverage 100
  minimum_coverage_by_file 100
  minimum_coverage branch: 100
end

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
