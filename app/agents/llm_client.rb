# One request to Groq: sends the messages and tool definitions, returns the assistant message.
# It does not run tools or keep the conversation; that is AgentLoop's job.
class LlmClient
  BASE_URL = "https://api.groq.com/openai/v1".freeze
  MODEL = "openai/gpt-oss-120b".freeze

  def chat(messages:, tools:)
    response = connection.post("chat/completions", request_body(messages, tools))
    response.body["choices"][0]["message"]
  end

  private

  # include_reasoning: false because Groq rejects the reasoning field when it is sent back.
  def request_body(messages, tools)
    { model: MODEL, messages: messages, tools: tools, include_reasoning: false }
  end

  def connection
    @connection ||= Faraday.new(BASE_URL, headers: { "Authorization" => "Bearer #{ENV.fetch('GROQ_API_KEY')}" }) do |faraday|
      faraday.request :json
      faraday.response :json
      faraday.response :raise_error
    end
  end
end
