module Rails
  module Contact
    class GoogleSyncJob < ApplicationJob
      queue_as :default

      def perform
        return unless Rails::Contact.configuration.google_sync_enabled

        Google::SyncService.new.sync!
      end
    end
  end
end
