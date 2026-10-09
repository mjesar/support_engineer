require "rails_helper"

RSpec.describe SupportAgent do
  # The prompt is found by name, so a renamed folder fails silently without this.
  it "loads its system prompt from app/prompts/support_agent" do
    system_prompt = described_class.new.chat.messages.first

    expect(system_prompt.content).to include("customer support agent")
  end

  it "replies with text", vcr: { cassette_name: "support_agent/replies" } do
    reply = described_class.new.ask("Say hi")

    expect(reply.content).to be_present
  end
end
