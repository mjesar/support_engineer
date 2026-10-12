# app/agents

The agent code. There are two ways to run the same agent here, on purpose.

| File | Role |
| --- | --- |
| `support_agent.rb` | **The agent the app uses.** A RubyLLM agent: model, tool allowlist and prompt. `chat.ask` runs the loop. |
| `agent_loop.rb`, `llm_client.rb`, `agent_tools.rb` | **The Lesson 4 hand-written version,** kept for learning. The same loop in plain Ruby with a step limit and a trace. Nothing else depends on it. |
| `triage.rb`, `next_step.rb` | Routing: classify a message, then pick the next step. |

Both versions use the same tool classes in `app/tools/`. See
[Lesson 4](../../docs/lessons/04-agent-loop.md) for how they compare.
