require "json"
require "fileutils"

module Rails
  module Contact
    module Google
      class TokenStore
        def initialize(path: Rails::Contact.configuration.google_token_path)
          @path = path
        end

        def access_token
          data.fetch("access_token")
        end

        def write!(payload)
          FileUtils.mkdir_p(File.dirname(@path))
          File.write(@path, payload.to_json)
        end

        private

        def data
          @data ||= JSON.parse(File.read(@path))
        rescue Errno::ENOENT
          raise Rails::Contact::Error, "Google token file missing at #{@path}"
        end
      end
    end
  end
end
