module Rails
  module Contact
    module Search
      Result = Struct.new(:records, :total_count, :page, :per_page, keyword_init: true) do
        def total_pages
          return 0 if total_count.zero? || per_page.zero?

          (total_count.to_f / per_page).ceil
        end
      end
    end
  end
end
