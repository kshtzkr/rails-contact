module Rails
  module Contact
    module ApplicationHelper
      def contact_initials(contact)
        [ contact.given_name, contact.family_name ].map { |part| part.to_s.first.to_s.upcase }.join
      end

      def contact_chip(value)
        value.presence || "-"
      end
    end
  end
end
