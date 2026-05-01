require "json"

module Rails
  module Contact
    module Google
      class Client
        PEOPLE_API_BASE = "https://people.googleapis.com/v1".freeze

        # Fields allowed in updatePersonFields (People API field mask); excludes Person metadata keys.
        UPDATE_MASK_FIELDS = %w[names emailAddresses phoneNumbers addresses biographies].freeze

        def initialize(access_token:)
          @connection = Faraday.new(url: PEOPLE_API_BASE) do |faraday|
            faraday.request :retry, max: 3, interval: 0.5, backoff_factor: 2
            faraday.response :raise_error
          end
          @access_token = access_token
        end

        def create_contact(payload)
          post("/people:createContact", payload)
        end

        def update_contact(resource_name, payload)
          mask = update_person_fields_mask(payload)
          raise ArgumentError, "updatePersonFields must not be empty" if mask.blank?

          patch("/#{resource_name}:updateContact", payload, { "updatePersonFields" => mask })
        end

        def delete_contact(resource_name)
          @connection.delete("/#{resource_name}") { |request| request.headers = headers }
        end

        private

        def post(path, payload)
          parse(@connection.post(path) do |request|
            request.headers = headers
            request.body = payload.to_json
          end)
        end

        def patch(path, payload, params = nil)
          parse(@connection.patch(path) do |request|
            request.headers = headers
            request.body = payload.to_json
            request.params.update(params) if params.present?
          end)
        end

        def parse(response)
          JSON.parse(response.body)
        end

        def headers
          { "Authorization" => "Bearer #{@access_token}", "Content-Type" => "application/json" }
        end

        def update_person_fields_mask(payload)
          h = payload.stringify_keys
          UPDATE_MASK_FIELDS.select { |field| h[field].present? }.join(",")
        end
      end
    end
  end
end
