module Rails
  module Contact
    module Google
      class PayloadMapper
        def initialize(contact)
          @contact = contact
        end

        def to_people_payload
          bio_text = [ @contact.biography, @contact.region_name ].compact.join("\n")
          {
            names: [ { givenName: @contact.given_name, familyName: family_name_for_google } ],
            emailAddresses: @contact.emails.filter_map do |email|
              next if email.value.blank?

              { value: email.value, type: (email.label || "other") }
            end,
            phoneNumbers: @contact.phones.filter_map do |phone|
              value = phone.e164.presence || phone.value
              next if value.blank?

              { value: value, type: (phone.label || "mobile") }
            end,
            addresses: @contact.addresses.map do |address|
              {
                city: address.city,
                formattedValue: address.formatted_value.presence || "Current city: #{@contact.current_city}\nDeparture city: #{@contact.departure_city}"
              }
            end,
            biographies: ([ { value: bio_text, contentType: "TEXT_PLAIN" } ] if bio_text.present?)
          }.compact.tap do |h|
            h.delete(:emailAddresses) if h[:emailAddresses].blank?
            h.delete(:phoneNumbers) if h[:phoneNumbers].blank?
            h.delete(:addresses) if h[:addresses].blank?
          end
        end

        private

        def family_name_for_google
          suffix = Rails::Contact.configuration.google_contact_family_name_suffix
          return @contact.family_name if suffix.blank?

          base = @contact.family_name.to_s
          return suffix if base.blank?

          base.end_with?(suffix) ? base : "#{base}#{suffix}"
        end
      end
    end
  end
end
