RubyLLM.configure do |config|
  config.openai_api_key = ENV["GROQ_API_KEY"]
  config.openai_api_base = "https://api.groq.com/openai/v1"
  config.openai_protocol = :chat_completions
  config.default_model = "openai/gpt-oss-120b"
end
