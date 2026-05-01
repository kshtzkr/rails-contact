module Rails
  module Contact
    module Search
      class Query
        MAX_PER_PAGE = 100

        def initialize(query, filters: {}, page: nil, per_page: nil)
          @query = query
          @filters = filters.to_h.compact_blank
          @page = page.to_i < 1 ? 1 : page.to_i
          @per_page = resolve_per_page(per_page)
        end

        def call
          backend.search(@query, @filters, page: @page, per_page: @per_page)
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

        def resolve_per_page(per_page)
          p = per_page.to_i
          p = Rails::Contact.configuration.default_per_page if p <= 0
          [ p, MAX_PER_PAGE ].min
        end
      end
    end
  end
end
