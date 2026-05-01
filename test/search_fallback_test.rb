require_relative "test_helper"

module Rails
  module Contact
    class SearchFallbackTest < Minitest::Test
      class FailingClient
        def search(*)
          raise StandardError, "boom"
        end
      end

      def test_falls_back_to_database_when_elasticsearch_fails
        contact = Contact.create!(given_name: "Aruna", family_name: "D", current_city: "Pune")
        contact.emails.create!(value: "aruna@example.com", primary: true)
        contact.phones.create!(value: "+919999999999", e164: "+919999999999", primary: true)

        backend = Search::Backends::Elasticsearch.new(client: FailingClient.new)
        result = backend.search("Aruna", {}, page: 1, per_page: 25)

        assert_equal 1, result.records.size
        assert_equal "Aruna", result.records.first.given_name
      end
    end
  end
end
