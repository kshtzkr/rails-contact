module Rails
  module Contact
    module ApplicationHelper
      def contact_initials(contact)
        [ contact.given_name, contact.family_name ].map { |part| part.to_s.first.to_s.upcase }.join
      end

      # A count the backend stopped at its cap is a floor, not a total, so it
      # renders as "10,000+". Rendering it plain reads as an exact number and
      # is how a guessed 1,005 once sized a WhatsApp broadcast.
      def contact_count_label(count, capped = false)
        "#{number_with_delimiter(count.to_i)}#{'+' if capped}"
      end

      def contact_chip(value)
        value.presence || "-"
      end
    end
  end
end
