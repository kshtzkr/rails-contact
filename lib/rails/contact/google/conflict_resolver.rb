module Rails
  module Contact
    module Google
      class ConflictResolver
        def initialize(local_contact, remote_modified_at:)
          @local_contact = local_contact
          @remote_modified_at = remote_modified_at
        end

        # v1 policy: last-write-wins by modified timestamp.
        def prefer_remote?
          return false if @remote_modified_at.blank?
          return true if @local_contact.updated_at.blank?

          @remote_modified_at > @local_contact.updated_at
        end
      end
    end
  end
end
