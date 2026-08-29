module Rails
  module Contact
    module Search
      Result = Struct.new(:records, :total_count, :page, :per_page, :count_capped, keyword_init: true) do
        # True when the backend stopped counting at its cap, so total_count is
        # a floor ("10,000+") rather than the whole set. Views must say so —
        # a capped number rendered plain reads as an exact count.
        def count_capped?
          !!count_capped
        end

        def total_pages
          return 0 if total_count.zero? || per_page.zero?

          (total_count.to_f / per_page).ceil
        end
      end
    end
  end
end
