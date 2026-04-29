require "rails/contact/version"
require "elasticsearch"
require "rails/contact/engine"
require "rails/contact/configuration"
require "rails/contact/orm"
require "rails/contact/routing"
require "rails/contact/search/query"
require "rails/contact/search/backends/database"
require "rails/contact/search/backends/elasticsearch"
require "rails/contact/csv/import_service"
require "rails/contact/google/client"
require "rails/contact/google/token_store"
require "rails/contact/google/payload_mapper"
require "rails/contact/google/conflict_resolver"
require "rails/contact/google/sync_service"
require "rails/contact/merge_contacts_service"

module Rails
  module Contact
    class Error < StandardError; end

    class << self
      attr_writer :configuration

      def configuration
        @configuration ||= Configuration.new
      end

      def configure
        yield(configuration)
      end
    end
  end
end
