require "json"

module Rails
  module Contact
    module Google
      class Client
        PEOPLE_API_BASE = "https://people.googleapis.com/v1".freeze

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
          patch("/#{resource_name}:updateContact", payload)
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

        def patch(path, payload)
          parse(@connection.patch(path) do |request|
            request.headers = headers
            request.body = payload.to_json
          end)
        end

        def parse(response)
          JSON.parse(response.body)
        end

        def headers
          {"Authorization" => "Bearer #{@access_token}", "Content-Type" => "application/json"}
        end
      end
    end
  end
end
