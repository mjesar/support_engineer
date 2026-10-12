require "rails_helper"

RSpec.describe AgentLoop do
  # Plays back canned replies in order, so the loop is tested without calling Groq.
  # It keeps a copy of the messages it was sent each time, to check what the model would have seen.
  let(:fake_client_class) do
    Class.new do
      attr_reader :calls

      def initialize(replies)
        @replies = replies
        @calls = []
      end

      def chat(messages:, tools:)
        @calls << messages.dup
        @replies.shift
      end
    end
  end

  let(:tools) { AgentTools.new([ GetOrderTool ]) }

  def tool_call_reply(name, arguments)
    { "role" => "assistant",
      "tool_calls" => [ { "id" => "call_1", "type" => "function",
                          "function" => { "name" => name, "arguments" => arguments } } ] }
  end

  def answer_reply(text)
    { "role" => "assistant", "content" => text }
  end

  it "returns the answer when the model does not ask for a tool" do
    client = fake_client_class.new([ answer_reply("Hello!") ])

    result = described_class.new(client: client, tools: tools).run("Say hi")

    expect(result.answer).to eq("Hello!")
    expect(result.stop_reason).to eq(:answered)
  end

  it "runs the requested tool and gives the result back to the model" do
    create(:order, id: 4242, status: "shipped")
    client = fake_client_class.new([ tool_call_reply("get_order", '{"order_id":4242}'), answer_reply("It shipped.") ])

    result = described_class.new(client: client, tools: tools).run("Where is my order 4242?")

    tool_message = client.calls.last.last
    expect(tool_message).to include(role: "tool", tool_call_id: "call_1")
    expect(JSON.parse(tool_message[:content])).to include("id" => 4242, "status" => "shipped")
    expect(result.answer).to eq("It shipped.")
  end

  it "stops with :step_limit when the model keeps asking for tools" do
    replies = Array.new(3) { tool_call_reply("get_order", '{"order_id":1}') }
    client = fake_client_class.new(replies)

    result = described_class.new(client: client, tools: tools, max_steps: 3).run("Where is my order 1?")

    expect(result.stop_reason).to eq(:step_limit)
    expect(result.answer).to be_nil
    expect(client.calls.size).to eq(3)
  end

  it "sends an unknown tool name back as an error and lets the model recover" do
    client = fake_client_class.new([ tool_call_reply("delete_order", '{"order_id":1}'), answer_reply("I cannot do that.") ])

    result = described_class.new(client: client, tools: tools).run("Delete order 1")

    expect(client.calls.last.last[:content]).to include("Unknown tool delete_order")
    expect(result.stop_reason).to eq(:answered)
  end

  it "sends arguments that are not valid JSON back as an error without running the tool" do
    client = fake_client_class.new([ tool_call_reply("get_order", "not json"), answer_reply("Sorry, let me retry.") ])
    allow(GetOrder).to receive(:call)

    result = described_class.new(client: client, tools: tools).run("Where is my order 1?")

    expect(GetOrder).not_to have_received(:call)
    expect(client.calls.last.last[:content]).to include("not valid JSON")
    expect(result.stop_reason).to eq(:answered)
  end

  it "records every model request and tool call in the trace" do
    create(:order, id: 4242)
    client = fake_client_class.new([ tool_call_reply("get_order", '{"order_id":4242}'), answer_reply("Done.") ])

    result = described_class.new(client: client, tools: tools).run("Where is my order 4242?")

    expect(result.trace.map { |entry| entry[:event] }).to eq(%i[model_request tool_call model_request])
    expect(result.trace[1]).to include(name: "get_order", arguments: '{"order_id":4242}')
    expect(result.trace.last[:message_count]).to eq(3)
  end

  # A fixed id and fixed dates keep the request body identical on every run, so the recording
  # replays on any day (see spec/agents/support_agent_spec.rb).
  it "answers a real question through the real model", vcr: { cassette_name: "agent_loop/looks_up_an_order" } do
    create(:order, id: 4242, status: "shipped", purchased_at: Time.utc(2026, 9, 20),
                   shipped_at: Time.utc(2026, 9, 24), delivered_at: nil,
                   estimated_delivery_at: Time.utc(2026, 10, 1))
    all_tools = AgentTools.new([ GetOrderTool, GetShipmentTool, GetCustomerTool, SearchOrdersTool ])

    result = described_class.new(client: LlmClient.new, tools: all_tools).run("Where is my order 4242?")

    tool_calls = result.trace.select { |entry| entry[:event] == :tool_call }
    expect(JSON.parse(tool_calls.first[:arguments])).to eq("order_id" => 4242)
    expect(result.stop_reason).to eq(:answered)
  end
end
