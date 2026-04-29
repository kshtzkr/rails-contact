require_relative "test_helper"

module Rails
  module Contact
    class PayloadMapperTest < Minitest::Test
      def test_maps_contact_to_people_payload
        contact = Contact.create!(given_name: "A", family_name: "B", current_city: "Delhi", departure_city: "Pune", region_name: "UK Tours")
        contact.emails.create!(value: "ab@example.com", primary: true, label: "work")
        contact.phones.create!(value: "+919999999999", e164: "+919999999999", primary: true, label: "mobile")
        contact.addresses.create!(city: "Delhi", departure_city: "Pune", formatted_value: "Current city: Delhi\nDeparture city: Pune")

        payload = Google::PayloadMapper.new(contact).to_people_payload
        assert_equal "A", payload[:names][0][:givenName]
        assert_equal "ab@example.com", payload[:emailAddresses][0][:value]
        assert_equal "+919999999999", payload[:phoneNumbers][0][:value]
      end
    end
  end
end
