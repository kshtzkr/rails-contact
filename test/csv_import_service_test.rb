require_relative "test_helper"
require "tempfile"

module Rails
  module Contact
    class CsvImportServiceTest < Minitest::Test
      def test_imports_and_dedupes_by_email
        file = Tempfile.new(["contacts", ".csv"])
        file.write("Enquirer Email,Enquirer First Name,Enquirer Last Name,Enquirer Phone,Enquirer Phone Country Code,Current City,Departure City,Region Name\n")
        file.write("john@example.com,John,Doe,9998887777,+91,Delhi,Mumbai,UK Tours\n")
        file.write("john@example.com,John,Doe,9998887777,+91,Delhi,Mumbai,UK Tours\n")
        file.rewind

        count = Csv::ImportService.new(path: file.path).import!

        assert_equal 2, count
        assert_equal 1, Contact.count
        assert_equal 1, Contact.first.emails.count
      ensure
        file.close
        file.unlink
      end
    end
  end
end
