require "rails_helper"

RSpec.describe Rails::Contact::Search::Backends::Elasticsearch do
  # Captures the query body so we can assert filter-clause shape without a real
  # Elasticsearch server. Returns an empty hit set so #search resolves cleanly.
  let(:captured) { {} }
  let(:client) do
    cap = captured
    Class.new do
      define_method(:initialize) { cap }
      define_method(:search) do |index:, body:|
        cap[:index] = index
        cap[:body]  = body
        { "hits" => { "total" => { "value" => 0 }, "hits" => [] } }
      end
    end.new
  end

  def filter_clauses(filters)
    described_class.new(client: client).search("", filters, page: 1, per_page: 25)
    captured[:body][:query][:bool][:filter]
  end

  it "emits a terms clause for a multi-select region array" do
    expect(filter_clauses("region" => [ "Europe", "Asia" ]))
      .to include({ terms: { region_name: [ "Europe", "Asia" ] } })
  end

  it "emits a scalar term clause for a single city" do
    expect(filter_clauses("city" => "Delhi"))
      .to include({ term: { current_city: "Delhi" } })
  end
end
