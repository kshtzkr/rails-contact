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

  # City became a multi-select in 0.1.18. The backend always accepted an array
  # here — what was missing was a permit that let one through.
  describe "city filter (multi-select)" do
    # Distinct from the factory default ("Delhi"), so alice/bob/carol above
    # can't drift into these expectations.
    let!(:pune)   { create(:rails_contact_contact, given_name: "Pia", current_city: "Pune") }
    let!(:jaipur) { create(:rails_contact_contact, given_name: "Dev", current_city: "Jaipur") }
    let!(:kochi)  { create(:rails_contact_contact, given_name: "Mira", current_city: "Kochi") }

    it "matches contacts in every selected city (array -> IN)" do
      expect(records("city" => [ "Pune", "Jaipur" ])).to match_array([ pune, jaipur ])
    end

    it "matches a single city exactly as before (scalar)" do
      expect(records("city" => "Kochi")).to match_array([ kochi ])
    end

    it "applies no constraint when the selection is blank only" do
      expect(records("city" => [ "" ]).count).to eq(Rails::Contact::Contact.count)
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

  describe "prefix search arms" do
    let!(:dave) do
      create(:rails_contact_contact,
             given_name: "Dave", family_name: "Sharma",
             metadata: { "company" => "Acme Travels", "job_title" => "Planner" }.to_json).tap do |c|
        c.emails.create!(value: "Dave@Example.com")
        c.phones.create!(value: "+91 98123 45670", e164: "+919812345670")
        c.labels = [ Rails::Contact::Label.find_or_create_by!(name: "vip-club") ]
      end
    end

    def search_for(query)
      described_class.new.search(query, {}, page: 1, per_page: 25).records
    end

    it "matches a given-name prefix case-insensitively" do
      expect(search_for("dav")).to include(dave)
    end

    it "matches a family-name prefix" do
      expect(search_for("sha")).to include(dave)
    end

    it "no longer matches a mid-string fragment (the index-serveable trade)" do
      expect(search_for("ave")).not_to include(dave)
    end

    it "matches an email prefix" do
      expect(search_for("dave@ex")).to include(dave)
    end

    it "matches bare digits against the +-prefixed e164" do
      expect(search_for("91981")).to include(dave)
    end

    it "matches the full plus-form phone prefix" do
      expect(search_for("+91981")).to include(dave)
    end

    it "matches a company prefix" do
      expect(search_for("acme")).to include(dave)
    end

    it "matches a job-title prefix" do
      expect(search_for("plan")).to include(dave)
    end

    it "matches a label prefix" do
      expect(search_for("vip")).to include(dave)
    end

    it "does not duplicate a contact matched by several arms" do
      # "dave" hits both the given_name and email arms; UNION dedupes ids.
      expect(search_for("dave").count(dave)).to eq(1)
    end
  end

  describe "result counting" do
    let(:backend) { described_class.new }

    def result(filters = {}, per_page: 25)
      backend.search("", filters, page: 1, per_page: per_page)
    end

    it "counts a filtered scope exactly" do
      # The production bug: a sheet holding one contact reported four figures
      # because the count was a planner estimate, not a count.
      expect(result({ "csv_import_id" => [ "imp_1" ] }).total_count).to eq(1)
    end

    it "counts the unfiltered scope exactly" do
      expect(result.total_count).to eq(Rails::Contact::Contact.count)
    end

    it "reports pages from the real count" do
      expect(result({}, per_page: 2).total_pages).to eq(2)
    end

    it "counts the same under a metadata sort" do
      # ORDER BY is stripped inside the count subquery so the LIMIT can
      # short-circuit; stripping it must not change the answer.
      config = Rails::Contact.configuration
      original = config.metadata_sorts
      config.metadata_sorts = { "score" => { key: "score" } }

      expect(result({ "sort" => "score" }).total_count).to eq(3)
    ensure
      config.metadata_sorts = original
    end

    context "when more rows match than the cap" do
      before { stub_const("#{described_class}::MAX_EXACT_COUNT", 2) }

      it "clamps the count to the cap and flags it" do
        expect(result.total_count).to eq(2)
        expect(result.count_capped?).to be(true)
      end

      it "does not flag a set that exactly fills the cap" do
        carol.destroy!

        expect(result.total_count).to eq(2)
        expect(result.count_capped?).to be(false)
      end
    end
  end
end
