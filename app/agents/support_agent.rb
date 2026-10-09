class SupportAgent < RubyLLM::Agent
  # Groq's models are not in RubyLLM's registry, so assume_model_exists is needed.
  # The Chat Completions protocol is set in the Groq initializer.
  model "openai/gpt-oss-120b", provider: :openai, assume_model_exists: true
end
