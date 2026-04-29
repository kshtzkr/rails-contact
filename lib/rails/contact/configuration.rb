module Rails
  module Contact
    class Configuration
      attr_accessor :contact_class_name, :elasticsearch_url, :search_backend,
                    :google_sync_enabled, :google_max_contacts, :rolling_window_sort,
                    :google_client_id, :google_client_secret, :google_redirect_uri,
                    :google_token_path, :reset_index_on_boot, :default_per_page

      def initialize
        @contact_class_name = "Rails::Contact::Contact"
        @elasticsearch_url = ENV.fetch("ELASTICSEARCH_URL", "http://127.0.0.1:9200")
        @search_backend = :elasticsearch
        @google_sync_enabled = false
        @google_max_contacts = 25_000
        @rolling_window_sort = :updated_at
        @google_client_id = ENV["GOOGLE_CLIENT_ID"]
        @google_client_secret = ENV["GOOGLE_CLIENT_SECRET"]
        @google_redirect_uri = ENV["GOOGLE_REDIRECT_URI"]
        @google_token_path = ENV.fetch("RAILS_CONTACT_GOOGLE_TOKEN_PATH", "tmp/rails_contact_google_token.json")
        @reset_index_on_boot = false
        @default_per_page = 25
      end
    end
  end
end
