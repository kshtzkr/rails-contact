require_relative "test_helper"

module Rails
  module Contact
    # City became a multi-select in 0.1.18. The database backend already
    # handled an array (`where(current_city: [...])`); what was missing was
    # permitting one. These cover the filtering itself and the two shapes the
    # controller has to survive: the blank option a <select multiple> always
    # submits, and an old single-value bookmark.
    class MultiSelectCityFilterTest < Minitest::Test
      def setup
        Contact.delete_all
        %w[Pune Mumbai Delhi].each_with_index do |city, idx|
          Contact.create!(given_name: "P#{idx}", family_name: "Q", current_city: city)
        end
      end

      def test_filters_on_several_cities_at_once
        result = Search::Backends::Database.new.search("", { "city" => %w[Pune Delhi] }, page: 1, per_page: 25)

        assert_equal %w[Delhi Pune], result.records.map(&:current_city).sort
      end

      def test_a_single_city_still_filters
        result = Search::Backends::Database.new.search("", { "city" => "Mumbai" }, page: 1, per_page: 25)

        assert_equal [ "Mumbai" ], result.records.map(&:current_city)
      end

      def test_blank_only_selection_does_not_narrow_to_nothing
        # The hidden blank entry Rails submits for an untouched multi-select is
        # stripped by normalize_multi_select!, so this arrives as no key at all.
        result = Search::Backends::Database.new.search("", {}, page: 1, per_page: 25)

        assert_equal 3, result.records.size
      end
    end
  end
end
