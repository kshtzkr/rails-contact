module Rails
  module Contact
    class GoogleSyncUnsyncedJob < ApplicationJob
      queue_as :default

      def perform
        return unless Rails::Contact.configuration.google_sync_enabled

        Google::SyncService.new.sync_unsynced!
      end
    end
  end
end
