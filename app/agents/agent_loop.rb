# The hand-written agent loop: ask the model, run the tools it requests, give it the results,
# and repeat until it answers in plain text. It owns the messages (the context); LlmClient
# and AgentTools stay stateless.
class AgentLoop
  # stop_reason is :answered or :step_limit, so the caller can tell a real answer from a cut-off.
  # trace lists every model request and tool call in order, to see afterwards what the agent did.
  Result = Struct.new(:answer, :stop_reason, :trace)

  def initialize(client:, tools:, max_steps: 5)
    @client = client
    @tools = tools
    @max_steps = max_steps
  end

  def run(question)
    messages = [ { role: "user", content: question } ]
    trace = []

    # The model decides when to stop, so a step limit keeps a confused one from looping forever.
    @max_steps.times do |step|
      trace << { event: :model_request, step: step + 1, message_count: messages.size }
      reply = @client.chat(messages: messages, tools: @tools.definitions)
      messages << reply
      return Result.new(reply["content"], :answered, trace) unless reply["tool_calls"]

      reply["tool_calls"].each { |tool_call| messages << tool_message(tool_call, trace) }
    end

    Result.new(nil, :step_limit, trace)
  end

  private

  def tool_message(tool_call, trace)
    function = tool_call["function"]
    result = run_tool(function)
    trace << { event: :tool_call, name: function["name"], arguments: function["arguments"], result: result }
    { role: "tool", tool_call_id: tool_call["id"], content: result.to_json }
  end

  # Bad arguments come back as an error the model can read and fix, like an unknown tool name.
  def run_tool(function)
    @tools.run(function["name"], JSON.parse(function["arguments"]))
  rescue JSON::ParserError
    { error: "Arguments for #{function['name']} are not valid JSON" }
  end
end
