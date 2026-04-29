module Rails
  module Contact
    module Search
      class Query
        def initialize(query, filters: {})
          @query = query
          @filters = filters.to_h.compact_blank
        end

        def call
          backend.search(@query, @filters)
        end

        private

        def backend
          case Rails::Contact.configuration.search_backend.to_sym
          when :elasticsearch
            Search::Backends::Elasticsearch.new
          else
            Search::Backends::Database.new
          end
        end
      end
    end
  end
end
