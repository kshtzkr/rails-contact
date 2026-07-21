require "rails_helper"

# Host-configured metadata filters + sorts (Configuration#metadata_filters /
# #metadata_sorts) applied by the database backend. The suite runs on SQLite;
# the PostgreSQL branches of the SQL are exercised by host applications.
RSpec.describe Rails::Contact::Search::Backends::Database do
  around do |example|
    config = Rails::Contact.configuration
    original_filters = config.metadata_filters
    original_sorts = config.metadata_sorts
    config.metadata_filters = {
      "tier" => { key: "quality_tier", type: :values, allowed: %w[hot warm standard] },
      "window" => { key: "booking_window", type: :values },
      "min_pax" => { key: "pax", type: :min_integer },
      "min_score" => { key: "score", type: :min_numeric },
      "vip" => { key: "tags", type: :tag, tag: "vip" }
    }
    config.metadata_sorts = { "score" => { key: "score" } }
    example.run
  ensure
    config.metadata_filters = original_filters
    config.metadata_sorts = original_sorts
  end

  def make(name, meta)
    create(:rails_contact_contact, given_name: name, metadata: meta.to_json)
  end

  let!(:hot) do
    make("Hot", "quality_tier" => "hot", "pax" => "12", "score" => "18.6",
                "booking_window" => "This week", "tags" => [ "vip" ])
  end
  let!(:warm) { make("Warm", "quality_tier" => "warm", "pax" => "2", "score" => "9.1") }
  let!(:junk) { make("Junk", "quality_tier" => "standard", "pax" => "TBD", "score" => "n/a") }

  def records(filters)
    described_class.new.search("", filters, page: 1, per_page: 25).records
  end

  describe ":values filters" do
    it "matches any of the selected values" do
      expect(records("tier" => [ "hot", "warm" ])).to match_array([ hot, warm ])
    end

    it "coerces a scalar like the other multi-selects" do
      expect(records("tier" => "hot")).to eq([ hot ])
    end

    it "discards values outside the whitelist" do
      expect(records("tier" => [ "hot", "'; DROP TABLE--" ])).to eq([ hot ])
    end

    it "applies no constraint when only junk was submitted" do
      expect(records("tier" => [ "'; DROP TABLE--" ])).to match_array([ hot, warm, junk ])
    end

    it "matches free values when no whitelist is configured" do
      expect(records("window" => [ "This week" ])).to eq([ hot ])
    end
  end

  describe ":min_integer / :min_numeric filters" do
    it "keeps rows at or above the floor and drops non-numeric values" do
      expect(records("min_pax" => "3")).to eq([ hot ])
      expect(records("min_pax" => "2")).to match_array([ hot, warm ])
    end

    it "accepts decimal floors" do
      expect(records("min_score" => "9.1")).to match_array([ hot, warm ])
      expect(records("min_score" => "10")).to eq([ hot ])
    end

    it "ignores a non-positive floor" do
      expect(records("min_pax" => "0")).to match_array([ hot, warm, junk ])
      expect(records("min_pax" => "abc")).to match_array([ hot, warm, junk ])
    end
  end

  describe ":tag filter" do
    it "matches contacts whose tag array contains the configured tag" do
      expect(records("vip" => "1")).to eq([ hot ])
    end

    it "is inert when the checkbox is off" do
      expect(records("vip" => "0")).to match_array([ hot, warm, junk ])
    end
  end

  describe "metadata sort" do
    it "orders by the metadata number descending, junk last" do
      expect(records("sort" => "score")).to eq([ hot, warm, junk ])
    end

    it "ignores an unknown sort value" do
      expect { records("sort" => "bogus") }.not_to raise_error
    end

    it "drops the sort under a free-text query instead of erroring (DISTINCT branch)" do
      result = described_class.new.search("Stone", { "sort" => "score" }, page: 1, per_page: 25)
      expect(result.records).to match_array([ hot, warm, junk ]) # factory family_name
    end
  end

  describe "key validation" do
    it "rejects a config key that is not a plain identifier" do
      Rails::Contact.configuration.metadata_filters = {
        "bad" => { key: "x'; DROP", type: :values }
      }
      expect { records("bad" => [ "1" ]) }.to raise_error(ArgumentError, /must match/)
    end

    it "rejects an unknown filter type" do
      Rails::Contact.configuration.metadata_filters = {
        "bad" => { key: "x", type: :wat }
      }
      expect { records("bad" => "1") }.to raise_error(ArgumentError, /unknown metadata filter type/)
    end
  end
end
