require "rails_helper"

RSpec.describe Rails::Contact::Filterable do
  it "removes blank values from filters" do
    dummy = Class.new do
      include Rails::Contact::Filterable

      def call(input)
        normalized_filters(input)
      end
    end.new

    params = ActionController::Parameters.new(city: "Delhi", region: "").permit(:city, :region)
    expect(dummy.call(params).to_h).to eq({ "city" => "Delhi" })
  end
end
