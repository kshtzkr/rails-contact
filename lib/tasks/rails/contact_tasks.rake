namespace :rails_contact do
  desc "Install initializer and mount routes"
  task install: :environment do
    puts "Run: rails generate rails:contact:install"
  end

  desc "Create Elasticsearch index and reindex all contacts"
  task reindex: :environment do
    backend = Rails::Contact::Search::Backends::Elasticsearch.new
    backend.create_index!
    Rails::Contact::Contact.includes(:emails, :phones).find_each do |contact|
      backend.upsert(contact)
    end
    puts "Indexed contacts into Elasticsearch"
  end

  desc "Run Google two-way sync for rolling window"
  task sync_google: :environment do
    Rails::Contact::GoogleSyncJob.perform_now
    puts "Google sync completed"
  end

  desc "Import contacts from CSV path (CSV_PATH=/path/file.csv)"
  task import_csv: :environment do
    path = ENV["CSV_PATH"]
    raise "Set CSV_PATH env var" if path.blank?

    count = Rails::Contact::Csv::ImportService.new(path: path).import!
    puts "Imported #{count} rows"
  end
end
