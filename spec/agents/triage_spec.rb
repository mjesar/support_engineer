require "rails_helper"

RSpec.describe Triage do
  # The schema and NextStep are two files that must agree. If an intent is added
  # to one and not the other, the model could return a value NextStep cannot route.
  it "allows exactly the intents NextStep can route" do
    intents = described_class.new.to_json_schema.dig("properties", "intent", "enum")

    expect(intents).to match_array(NextStep::STEPS.keys)
  end
end
