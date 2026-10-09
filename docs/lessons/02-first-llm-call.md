# Lesson 2: the first LLM call

The app talks to a model for the first time: one agent class, a system prompt in its own file, and a
test that does not call the API on every run.

Last updated: 2026-10-09

## Status

- [x] `ruby_llm` 2.1.0 added, Groq and Gemini configured in initializers
- [x] `SupportAgent` (a `RubyLLM::Agent`) answers through Groq (`openai/gpt-oss-120b`)
- [x] System prompt as a template file
- [x] VCR and WebMock set up, with the Groq key filtered out of recordings
- [ ] First agent spec with a recorded cassette
- [ ] Structured output tested in the console on the chosen Groq model
- [ ] Tag `lesson-02` on the merge commit of the lesson 2 pull request

## What was built

```
config/initializers/ruby_llm_groq.rb     Groq key, URL and protocol (through the OpenAI settings)
config/initializers/ruby_llm_gemini.rb   Gemini key
app/agents/support_agent.rb              the agent: which model, nothing else
app/prompts/support_agent/instructions.txt.erb   the system prompt
spec/support/vcr.rb                      records LLM calls once, replays them after
```

The agent finds its prompt by name: class `SupportAgent` reads `app/prompts/support_agent/instructions.txt.erb`.
Rename one without the other and the prompt silently stops loading.

## Groq through RubyLLM 2.x

RubyLLM has no Groq provider, so Groq is reached through its OpenAI-compatible API. Three things were
needed, and each one failed first:

- `openai_api_base` points the OpenAI settings at Groq's URL.
- `openai_protocol = :chat_completions`, because 2.x defaults OpenAI to the newer Responses API and Groq
  rejects its `include` field (`Field 'include' is not supported`).
- `assume_model_exists: true`, because Groq's model names are not in RubyLLM's registry.

There is only one set of OpenAI settings globally, so real OpenAI could not be used next to Groq without
a separate `RubyLLM.context`. That is not needed yet.

Models retire: `llama-3.3-70b-versatile` is gone from Groq and `gemini-2.5-flash` is closed to new users.
List what a key can use with a call to the provider's `/models` endpoint before picking a model.

## Testing an LLM call

WebMock blocks real HTTP in specs. VCR lets one real call through, saves it as a cassette in
`spec/cassettes/`, and replays it on later runs, so specs are fast, free and repeatable.

- The Groq key is replaced with `<GROQ_API_KEY>` before anything is saved, so cassettes are safe to commit.
- Requests are matched on method, URL and body, so changing the prompt or the question forces a new
  recording instead of replaying an old answer.
- A cassette tests the wiring (config, prompt loading, parsing the reply), not whether the answer is good.
  Answer quality is measured with evals in lesson 10. Keep the cassette specs few.
