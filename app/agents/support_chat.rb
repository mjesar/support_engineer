class SupportChat
  # Groq speaks only the Chat Completions protocol, and its models are not in
  # RubyLLM's registry, so every chat needs these three options.
  def self.build
    RubyLLM.chat(provider: :openai, protocol: :chat_completions, assume_model_exists: true)
  end
end
