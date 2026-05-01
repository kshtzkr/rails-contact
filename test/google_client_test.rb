require_relative "test_helper"

module Rails
  module Contact
    class GoogleClientTest < Minitest::Test
      def test_update_person_fields_mask_lists_only_populated_person_fields
        payload = {
          names: [ { givenName: "A" } ],
          emailAddresses: [ { value: "a@b.com" } ],
          resourceName: "people/1",
          etag: "e"
        }
        h = payload.stringify_keys
        mask = Google::Client::UPDATE_MASK_FIELDS.select { |field| h[field].present? }.join(",")

        assert_equal "names,emailAddresses", mask
      end
    end
  end
end
