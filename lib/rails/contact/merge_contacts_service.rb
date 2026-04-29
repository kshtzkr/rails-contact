require "json"

module Rails
  module Contact
    class MergeContactsService
      def initialize(source_id:, target_id:)
        @source = Contact.includes(:emails, :phones, :addresses, :websites, :events, :labels).find(source_id)
        @target = Contact.includes(:emails, :phones, :addresses, :websites, :events, :labels).find(target_id)
      end

      def call
        raise ArgumentError, "Source and target must be different" if @source.id == @target.id

        Contact.transaction do
          merge_scalar_fields
          merge_nested_records
          merge_labels
          @target.save!
          @source.destroy!
        end
        @target
      end

      private

      def merge_scalar_fields
        %i[given_name family_name current_city departure_city region_name biography].each do |field|
          @target[field] = @target[field].presence || @source[field]
        end
        @target.metadata = metadata_hash(@source).merge(metadata_hash(@target))
      end

      def merge_nested_records
        merge_records(@source.emails, @target.emails, :value)
        merge_records(@source.phones, @target.phones, :e164)
        merge_records(@source.addresses, @target.addresses, :formatted_value)
        merge_records(@source.websites, @target.websites, :url)
        merge_records(@source.events, @target.events, :event_type)
      end

      def merge_labels
        @target.labels = (@target.labels + @source.labels).uniq
      end

      def merge_records(source_records, target_records, key)
        existing = target_records.map(&key).compact
        source_records.each do |record|
          next if existing.include?(record.public_send(key))

          attrs = record.attributes.except("id", "contact_id", "created_at", "updated_at")
          target_records.build(attrs)
        end
      end

      def metadata_hash(contact)
        value = contact.metadata
        return value if value.is_a?(Hash)
        return JSON.parse(value.presence || "{}") if value.is_a?(String)

        {}
      rescue JSON::ParserError
        {}
      end
    end
  end
end
