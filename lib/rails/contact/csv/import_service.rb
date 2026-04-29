require "csv"

module Rails
  module Contact
    module Csv
      class ImportService
        HEADER_MAP = {
          "Enquirer First Name" => :given_name,
          "Enquirer Last Name" => :family_name,
          "Current City" => :current_city,
          "Departure City" => :departure_city,
          "Region Name" => :region_name
        }.freeze

        def initialize(path:, dedupe_key: :email)
          @path = path
          @dedupe_key = dedupe_key
        end

        def import!
          imported = 0
          CSV.foreach(@path, headers: true) do |row|
            import_row(row.to_h)
            imported += 1
          end
          imported
        end

        private

        def import_row(row)
          attrs = build_attributes(row)
          contact = find_or_initialize(row)
          contact.assign_attributes(attrs)
          contact.save!
          upsert_associations(contact, row)
          Rails::Contact::IndexContactJob.perform_later(contact.id)
        end

        def build_attributes(row)
          HEADER_MAP.each_with_object({}) do |(csv_key, attr), memo|
            value = row[csv_key].to_s.strip
            memo[attr] = (value == "blank" ? nil : value.presence)
          end
        end

        def find_or_initialize(row)
          email = normalize_email(row["Enquirer Email"])
          return Rails::Contact::Contact.new if email.blank?
          return Rails::Contact::Contact.new if @dedupe_key != :email

          Rails::Contact::Contact.joins(:emails).where(rails_contact_contact_emails: { value: email }).first || Rails::Contact::Contact.new
        end

        def upsert_associations(contact, row)
          email = normalize_email(row["Enquirer Email"])
          primary_phone = normalize_phone(row["Enquirer Phone Country Code"], row["Enquirer Phone"])
          alt_phone = normalize_phone(row["Alternate Wa Phone Country Code"], row["Alternate Wa Phone"])

          contact.emails.find_or_create_by!(value: email, primary: true, label: "work") if email.present?
          if primary_phone.present?
            contact.phones.find_or_create_by!(value: primary_phone, e164: primary_phone, primary: true, label: "mobile")
          end
          if alt_phone.present?
            contact.phones.find_or_create_by!(value: alt_phone, e164: alt_phone, primary: false, label: "whatsapp")
          end

          formatted_value = "Current city: #{contact.current_city}\nDeparture city: #{contact.departure_city}"
          contact.addresses.find_or_create_by!(city: contact.current_city, departure_city: contact.departure_city, formatted_value: formatted_value)
        end

        def normalize_email(value)
          clean = value.to_s.strip.downcase
          clean.presence
        end

        def normalize_phone(country_code, number)
          digits = number.to_s.gsub(/\D+/, "")
          return nil if digits.blank?
          prefix = country_code.to_s.strip
          prefix = "+#{prefix}" unless prefix.start_with?("+")
          "#{prefix}#{digits}"
        end
      end
    end
  end
end
