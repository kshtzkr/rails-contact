require "rails_helper"

RSpec.describe Rails::Contact::Search::Backends::Database do
  # metadata is a text column read back through JSON.parse, so store JSON for
  # the SQL `metadata->>'csv_import_id'` extraction to resolve.
  def make(name, import_id)
    create(:rails_contact_contact, given_name: name, metadata: { "csv_import_id" => import_id }.to_json)
  end

  let!(:alice) { make("Alice", "imp_1") }
  let!(:bob)   { make("Bob", "imp_2") }
  let!(:carol) { make("Carol", "imp_3") }

  def records(filters)
    described_class.new.search("", filters, page: 1, per_page: 25).records
  end

  describe "csv_import_id filter (multi-select)" do
    it "matches contacts across every selected import (array -> IN)" do
      expect(records("csv_import_id" => [ "imp_1", "imp_2" ])).to match_array([ alice, bob ])
    end

    it "matches a single import exactly as before (scalar)" do
      expect(records("csv_import_id" => "imp_1")).to match_array([ alice ])
    end

    it "applies no constraint when the selection is blank only" do
      expect(records("csv_import_id" => [ "" ])).to match_array([ alice, bob, carol ])
    end
  end

  describe "query sanitization" do
    def search_for(query)
      described_class.new.search(query, {}, page: 1, per_page: 25).records
    end

    it "treats % as a literal, not a match-everything wildcard" do
      expect(search_for("%")).to be_empty
    end

    it "still matches a real substring" do
      expect(search_for("Ali")).to include(alice)
    end

    it "does not blow up on pathologically long input" do
      expect { search_for("a" * 1000) }.not_to raise_error
    end
  end
end
