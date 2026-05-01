module Rails
  module Contact
    module Search
      module Backends
        class Elasticsearch
          INDEX = "rails_contact_contacts".freeze

          class << self
            def default_client
              @default_client ||= ::Elasticsearch::Client.new(url: Rails::Contact.configuration.elasticsearch_url)
            end

            def default_client=(client)
              @default_client = client
            end

            def clear_default_client!
              @default_client = nil
            end
          end

          def initialize(client: nil)
            @client = client || self.class.default_client
          end

          def search(query, filters)
            response = @client.search(index: INDEX, body: search_body(query, filters))
            ids = response.fetch("hits", {}).fetch("hits", []).map { |doc| doc["_id"] }
            records_by_id = Contact.where(id: ids).index_by { |record| record.id.to_s }
            ids.filter_map { |id| records_by_id[id.to_s] }
          rescue StandardError
            Search::Backends::Database.new.search(query, filters)
          end

          def upsert(contact)
            @client.index(index: INDEX, id: contact.id, body: document_for(contact))
          end

          def remove(contact_id)
            @client.delete(index: INDEX, id: contact_id)
          rescue StandardError
            nil
          end

          def create_index!
            return if @client.indices.exists?(index: INDEX)

            @client.indices.create(index: INDEX, body: index_mapping)
          end

          private

          def index_mapping
            {
              settings: {
                analysis: {
                  analyzer: {
                    folding_analyzer: {
                      tokenizer: "standard",
                      filter: [ "lowercase", "asciifolding" ]
                    }
                  }
                }
              },
              mappings: {
                properties: {
                  full_name: { type: "text", analyzer: "folding_analyzer" },
                  emails: { type: "keyword" },
                  phones_e164: { type: "keyword" },
                  labels: { type: "keyword" },
                  company: { type: "text", analyzer: "folding_analyzer" },
                  job_title: { type: "text", analyzer: "folding_analyzer" },
                  region_name: { type: "keyword" },
                  current_city: { type: "keyword" },
                  departure_city: { type: "keyword" },
                  starred: { type: "boolean" },
                  sync_eligible: { type: "boolean" },
                  updated_at: { type: "date" }
                }
              }
            }
          end

          def search_body(query, filters)
            {
              size: Rails::Contact.configuration.default_per_page,
              sort: [ { updated_at: { order: "desc" } }, { id: { order: "desc" } } ],
              query: {
                bool: {
                  must: search_clause(query),
                  filter: filter_clauses(filters)
                }
              }
            }
          end

          def search_clause(query)
            return [ { match_all: {} } ] if query.blank?

            [ {
              multi_match: {
                query: query,
                fields: [ "full_name^3", "emails^2", "phones_e164", "company^2", "job_title", "labels^2" ],
                fuzziness: "AUTO"
              }
            } ]
          end

          def filter_clauses(filters)
            clauses = []
            clauses << { term: { current_city: filters["city"] } } if filters["city"].present?
            clauses << { term: { region_name: filters["region"] } } if filters["region"].present?
            unless filters["starred"].nil?
              starred_value = ActiveModel::Type::Boolean.new.cast(filters["starred"])
              clauses << { term: { starred: starred_value } }
            end
            unless filters["sync_eligible"].nil?
              value = ActiveModel::Type::Boolean.new.cast(filters["sync_eligible"])
              clauses << { term: { sync_eligible: value } }
            end
            clauses
          end

          def document_for(contact)
            {
              id: contact.id,
              full_name: contact.full_name,
              emails: contact.emails.map(&:value),
              phones_e164: contact.phones.map(&:e164),
              labels: contact.labels.map(&:name),
              company: contact.meta(:company),
              job_title: contact.meta(:job_title),
              region_name: contact.region_name,
              current_city: contact.current_city,
              departure_city: contact.departure_city,
              starred: contact.starred,
              sync_eligible: contact.sync_eligible,
              updated_at: contact.updated_at
            }
          end
        end
      end
    end
  end
end
