module Rails
  module Contact
    module Google
      class SyncService
        def initialize(token_store: TokenStore.new, client: nil)
          @token_store = token_store
          @client = client || Client.new(access_token: @token_store.access_token)
        end

        def sync!
          Rails::Contact::Contact.sync_window.includes(:emails, :phones, :addresses).each do |contact|
            sync_contact(contact)
          end
        end

        def unsynced_contacts_scope
          Rails::Contact::Contact.where("google_resource_name IS NULL OR google_resource_name = ?", "")
        end

        def sync_unsynced!
          unsynced_contacts_scope.in_batches(of: 100) do |batch|
            batch.preload(:emails, :phones, :addresses).each do |contact|
              sync_contact(contact)
            rescue StandardError => e
              Rails.logger.error(
                "[Rails::Contact] Google sync_unsynced failed for contact #{contact.id}: #{e.class}: #{e.message}"
              )
            end
          end
        end

        def sync_contact(contact)
          payload = PayloadMapper.new(contact).to_people_payload
          response = if contact.google_resource_name.present?
                       body = payload.merge(
                         resourceName: contact.google_resource_name,
                         etag: contact.google_etag
                       ).compact
                       @client.update_contact(contact.google_resource_name, body)
          else
                       @client.create_contact(payload)
          end

          contact.update!(
            google_resource_name: response["resourceName"] || contact.google_resource_name,
            google_etag: response["etag"] || contact.google_etag,
            google_last_modified_at: Time.current,
            last_synced_at: Time.current
          )
        end
      end
    end
  end
end
