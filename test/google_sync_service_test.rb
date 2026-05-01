require_relative "test_helper"

module Rails
  module Contact
    class GoogleSyncServiceTest < Minitest::Test
      FakeTokenStore = Struct.new(:access_token)

      class FakeClient
        attr_reader :created, :updates

        def initialize
          @created = []
          @updates = []
        end

        def create_contact(payload)
          @created << payload
          { "resourceName" => "people/123", "etag" => "abc" }
        end

        def update_contact(resource_name, payload)
          @updates << [ resource_name, payload ]
          { "resourceName" => resource_name, "etag" => "def" }
        end
      end

      def setup
        Rails::Contact.configuration.google_max_contacts = 1
      end

      def test_syncs_only_within_rolling_window
        older = Contact.create!(given_name: "Old", updated_at: 2.days.ago, created_at: 2.days.ago)
        newer = Contact.create!(given_name: "New", updated_at: Time.current, created_at: Time.current)
        [ older, newer ].each do |contact|
          contact.emails.create!(value: "#{contact.given_name.downcase}@example.com", primary: true)
          contact.phones.create!(value: "+911234567890", e164: "+911234567890", primary: true)
        end

        client = FakeClient.new
        Google::SyncService.new(token_store: FakeTokenStore.new("token"), client: client).sync!

        assert_equal 1, client.created.size
        assert_empty client.updates
        assert_nil older.reload.google_resource_name
        refute_nil newer.reload.google_resource_name
      end

      def test_update_sends_resource_name_and_etag_in_body
        contact = Contact.create!(
          given_name: "Pat",
          google_resource_name: "people/existing",
          google_etag: "etag-from-db"
        )
        contact.emails.create!(value: "pat@example.com", primary: true)

        client = FakeClient.new
        Google::SyncService.new(token_store: FakeTokenStore.new("token"), client: client).sync_contact(contact)

        assert_empty client.created
        assert_equal 1, client.updates.size
        resource_name, payload = client.updates.first
        assert_equal "people/existing", resource_name
        assert_equal "people/existing", payload[:resourceName]
        assert_equal "etag-from-db", payload[:etag]
        assert_equal "pat@example.com", payload[:emailAddresses].first[:value]
      end
    end
  end
end
