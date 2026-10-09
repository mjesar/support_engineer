require "rails_helper"

RSpec.describe SupportAgent do
  it "replies with text", vcr: { cassette_name: "support_agent/replies" } do
    reply = described_class.new.ask("Say hi")

    expect(reply.content).to be_present
  end
end
