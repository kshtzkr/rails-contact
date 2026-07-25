module Rails
  module Contact
    class Configuration
      attr_accessor :contact_class_name, :elasticsearch_url, :search_backend,
                    :google_sync_enabled, :google_sync_ui_on_index, :google_max_contacts, :rolling_window_sort,
                    :google_client_id, :google_client_secret, :google_redirect_uri,
                    :google_token_path, :reset_index_on_boot, :default_per_page,
                    :inherit_host_layout,
                    :google_contact_family_name_suffix,
                    :metadata_filters, :metadata_sorts

      def initialize
        @contact_class_name = "Rails::Contact::Contact"
        @elasticsearch_url = ENV.fetch("ELASTICSEARCH_URL", "http://127.0.0.1:9200")
        @search_backend = :elasticsearch
        @google_sync_enabled = false
        # When true with google_sync_enabled, the default index renders _google_sync_panel (host can override that partial).
        @google_sync_ui_on_index = true
        @google_max_contacts = 25_000
        @rolling_window_sort = :updated_at
        @google_client_id = ENV["GOOGLE_CLIENT_ID"]
        @google_client_secret = ENV["GOOGLE_CLIENT_SECRET"]
        @google_redirect_uri = ENV["GOOGLE_REDIRECT_URI"]
        @google_token_path = ENV.fetch("RAILS_CONTACT_GOOGLE_TOKEN_PATH", "tmp/rails_contact_google_token.json")
        # Optional: appended to familyName in Google People payloads only (not stored on Contact). Blank = disabled.
        @google_contact_family_name_suffix = ENV["RAILS_CONTACT_GOOGLE_CONTACT_FAMILY_NAME_SUFFIX"]&.presence
        @reset_index_on_boot = false
        @default_per_page = 25
        # When true (default), engine pages use the host app +layout+ named +application+ so
        # importmap/Turbo match the rest of the app. Engine CSS and nested-field JS are still
        # injected from gem templates so behavior does not depend on the engine layout asset tags.
        @inherit_host_layout = true
        # Declarative filters over Contact#metadata, keyed by the request param
        # name. The host app decides which metadata keys are filterable; the
        # engine permits the params, guards the SQL, and applies the filter
        # (database backend only). Example:
        #
        #   config.metadata_filters = {
        #     "tier"      => { key: "quality_tier", type: :values, allowed: %w[hot warm standard] },
        #     "min_pax"   => { key: "pax",          type: :min_integer },
        #     "min_score" => { key: "score",        type: :min_numeric },
        #     "vip"       => { key: "tags",         type: :tag, tag: "vip" }
        #   }
        #
        # :values      — multi-select; matches metadata->>key IN (...). Optional
        #                :allowed whitelist discards anything else.
        # :min_integer — numeric floor over an integer-ish metadata string;
        #                non-numeric stored values are filtered out, never cast.
        # :min_numeric — same, but accepts decimals.
        # :tag         — checkbox; matches when the metadata key (a JSON array)
        #                contains :tag. Param value "1" switches it on.
        # :exclude     — hides rows whose key equals :value. Add default: :on
        #                to apply it even when the param is absent; an
        #                explicit "0" shows everything. Rows missing the key
        #                always pass.
        @metadata_filters = {}
        # Sort options over numeric metadata, keyed by the ?sort= param value:
        #
        #   config.metadata_sorts = { "score" => { key: "score" } }
        #
        # Sorts descending, non-numeric values last, ties broken by recency.
        # Ignored while a free-text q search is active: the search branch runs
        # SELECT DISTINCT and PostgreSQL rejects ordering by an expression that
        # is not in the select list, so search results keep recency order.
        @metadata_sorts = {}
      end
    end
  end
end
