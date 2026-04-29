module Rails
  module Contact
    module Filterable
      private

      def normalized_filters(params)
        params.to_h.compact_blank
      end
    end
  end
end
