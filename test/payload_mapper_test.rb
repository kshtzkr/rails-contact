require_relative "test_helper"

module Rails
  module Contact
    class PayloadMapperTest < Minitest::Test
      def setup
        @prev_suffix = Rails::Contact.configuration.google_contact_family_name_suffix
        Rails::Contact.configuration.google_contact_family_name_suffix = nil
      end

      def teardown
        Rails::Contact.configuration.google_contact_family_name_suffix = @prev_suffix
      end

      def test_maps_contact_to_people_payload
        contact = Contact.create!(given_name: "A", family_name: "B", current_city: "Delhi", departure_city: "Pune", region_name: "UK Tours")
        contact.emails.create!(value: "ab@example.com", primary: true, label: "work")
        contact.phones.create!(value: "+919999999999", e164: "+919999999999", primary: true, label: "mobile")
        contact.addresses.create!(city: "Delhi", departure_city: "Pune", formatted_value: "Current city: Delhi\nDeparture city: Pune")

        payload = Google::PayloadMapper.new(contact).to_people_payload
        assert_equal "A", payload[:names][0][:givenName]
        assert_equal "B", payload[:names][0][:familyName]
        assert_equal "ab@example.com", payload[:emailAddresses][0][:value]
        assert_equal "+919999999999", payload[:phoneNumbers][0][:value]
      end

      def test_optional_family_name_suffix_is_applied_when_set
        Rails::Contact.configuration.google_contact_family_name_suffix = "_x"
        contact = Contact.create!(given_name: "A", family_name: "B")

        payload = Google::PayloadMapper.new(contact).to_people_payload
        assert_equal "B_x", payload[:names][0][:familyName]
      end

      def test_family_name_suffix_is_idempotent_when_already_present
        Rails::Contact.configuration.google_contact_family_name_suffix = "_x"
        contact = Contact.create!(given_name: "A", family_name: "B_x")

        payload = Google::PayloadMapper.new(contact).to_people_payload
        assert_equal "B_x", payload[:names][0][:familyName]
      end

      def test_blank_family_name_with_suffix_sends_suffix_only
        Rails::Contact.configuration.google_contact_family_name_suffix = "_x"
        contact = Contact.create!(given_name: "A", family_name: nil)

        payload = Google::PayloadMapper.new(contact).to_people_payload
        assert_equal "_x", payload[:names][0][:familyName]
      end
    end
  end
end
