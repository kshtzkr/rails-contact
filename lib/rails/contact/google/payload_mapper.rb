module Rails
  module Contact
    module Google
      class PayloadMapper
        def initialize(contact)
          @contact = contact
        end

        def to_people_payload
          {
            names: [ { givenName: @contact.given_name, familyName: @contact.family_name } ],
            emailAddresses: @contact.emails.map { |email| { value: email.value, type: (email.label || "other") } },
            phoneNumbers: @contact.phones.map { |phone| { value: phone.e164.presence || phone.value, type: (phone.label || "mobile") } },
            addresses: @contact.addresses.map do |address|
              {
                city: address.city,
                formattedValue: address.formatted_value.presence || "Current city: #{@contact.current_city}\nDeparture city: #{@contact.departure_city}"
              }
            end,
            biographies: [ { value: [ @contact.biography, @contact.region_name ].compact.join("\n") } ]
          }.compact
        end
      end
    end
  end
end
