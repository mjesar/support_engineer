class SupportChat
  # Groq's models are not in RubyLLM's registry, so every chat needs
  # assume_model_exists. The Chat Completions protocol is set in the Groq initializer.
  def self.build
    RubyLLM.chat(provider: :openai, assume_model_exists: true)
  end
end
