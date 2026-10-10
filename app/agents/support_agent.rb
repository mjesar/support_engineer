class SupportAgent < RubyLLM::Agent
  # Groq's models are not in RubyLLM's registry, so assume_model_exists is needed.
  # The Chat Completions protocol is set in the Groq initializer.
  model "openai/gpt-oss-120b", provider: :openai, assume_model_exists: true

  # The allowlist: the model can only call what is named here.
  tools GetOrderTool, GetShipmentTool, GetCustomerTool, SearchOrdersTool

  # RubyLLM sends the model's reasoning text back after a tool call and Groq rejects that
  # field (property 'reasoning_content' is unsupported), so ask Groq not to return it.
  provider_options include_reasoning: false
end
