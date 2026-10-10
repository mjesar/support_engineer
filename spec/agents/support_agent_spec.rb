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

  # The tool result is part of the second request, and VCR matches on the body. A fixed id and
  # fixed dates keep that body identical on every run, so the recording replays on any day.
  it "looks up the order with its tool and answers from the result",
     vcr: { cassette_name: "support_agent/looks_up_an_order" } do
    create(:order, id: 4242, status: "shipped", purchased_at: Time.utc(2026, 9, 20),
                   shipped_at: Time.utc(2026, 9, 24), delivered_at: nil,
                   estimated_delivery_at: Time.utc(2026, 10, 1))
    agent = described_class.new

    reply = agent.ask("Where is my order 4242?")

    tool_calls = agent.messages.select(&:tool_call?).flat_map { |message| message.tool_calls.values }
    expect(tool_calls.first.name).to eq("get_order")
    expect(tool_calls.first.arguments).to eq("order_id" => 4242)
    expect(reply.content).to match(/shipped/i)
  end
end
