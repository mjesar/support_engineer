# The hand-written agent loop: ask the model, run the tools it requests, give it the results,
# and repeat until it answers in plain text. It owns the messages (the context); LlmClient
# and AgentTools stay stateless.
class AgentLoop
  def initialize(client:, tools:)
    @client = client
    @tools = tools
  end

  def run(question)
    messages = [{ role: "user", content: question }]

    loop do
      reply = @client.chat(messages: messages, tools: @tools.definitions)
      messages << reply
      return reply["content"] unless reply["tool_calls"]

      reply["tool_calls"].each { |tool_call| messages << tool_message(tool_call) }
    end
  end

  private

  def tool_message(tool_call)
    function = tool_call["function"]
    result = @tools.run(function["name"], JSON.parse(function["arguments"]))
    { role: "tool", tool_call_id: tool_call["id"], content: result.to_json }
  end
end
