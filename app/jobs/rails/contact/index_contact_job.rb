module Rails
  module Contact
    class IndexContactJob < ApplicationJob
      queue_as :default

      def perform(contact_id, remove: false)
        backend = Search::Backends::Elasticsearch.new
        return backend.remove(contact_id) if remove

        contact = Contact.includes(:emails, :phones).find_by(id: contact_id)
        return if contact.nil?

        backend.create_index!
        backend.upsert(contact)
      end
    end
  end
end
