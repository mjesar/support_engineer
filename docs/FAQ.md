# FAQ

Questions that came up while building, with short answers. New entries go at the bottom.

## What is the difference between an MCP client and an MCP server?

MCP (Model Context Protocol) is a shared language between AI apps and the tools they use. An MCP
**server** offers tools. An MCP **client** uses them. Because both sides speak the same protocol, any
client can talk to any server without custom code.

- **Server:** has the capabilities. It publishes a list of tools, each with a name, a description and
  an input schema, and runs one when asked.
- **Client:** has the model. It connects to a server, asks which tools exist, gives that list to the
  LLM, and when the model picks a tool it sends the call to the server and returns the result.

```
client (has the LLM)                      server (has the tools)
        │  "what tools do you have?"  →          │
        │  ← [get_order, list_products]          │
        │  "call get_order(id: 1)"    →          │
        │  ← { status: "shipped", ... }          │
```

Examples: Claude Desktop and MCP Inspector are clients. A server that exposes store data is a server.
An app can be both at once.

### How this relates to this project

RubyLLM's own tool calling is not MCP. A `RubyLLM::Tool` runs inside the Rails process, and only that
app can use it. RubyLLM's MCP code (`ruby_llm/mcp`) is a client only, so it can use someone else's
server but cannot publish tools.

| Where | Role | What happens |
| --- | --- | --- |
| Lesson 3 | neither | tools run in-process through RubyLLM, no protocol involved |
| Lesson 5 | server | the same Ruby tools are published with the `mcp` gem, so Claude and Inspector can call them |

This is why a tool is a plain Ruby class (for example `GetOrder`) with a thin wrapper per consumer:
one `RubyLLM::Tool` wrapper for the agent, and later one `MCP::Tool` wrapper for the server. The
logic is written once.

## If RubyLLM already has tool calling, why does Lesson 5 use the `mcp` gem?

They do two different jobs, in opposite directions.

- **RubyLLM tools** let your own app's model call your own code. The tool runs in the same process
  and nobody outside can see it.
- **An MCP server** lets someone else's AI app (Claude, MCP Inspector) call your code over the
  network. That needs an endpoint that speaks the MCP protocol: listing tools, calling them,
  sessions and authentication.

RubyLLM's MCP support (the `ruby_llm/mcp` code, checked in ruby_llm 2.1.0 on 2026-10-10) is a client
only. It can use tools from someone else's server, but it cannot publish yours. Publishing is what
the `mcp` gem does.

The standalone `ruby_llm-mcp` gem is the same client. Version 2.1.0 of `ruby_llm` already ships that
code, with a different setup style (a `RubyLLM::MCP` subclass passed to `chat.with_mcp`), so the
separate gem is likely not needed. Check its releases page before adding it.

## Can my own agent use a tool that is built as an MCP tool, and what does that cost?

Yes, but only through the MCP client and a running server. An `MCP::Tool` is not a `RubyLLM::Tool`,
so it cannot be handed to `chat.with_tools` directly.

```
agent ──(MCP client)──► your MCP server ──► MCP::Tool ──► your code
```

Whether RubyLLM can call an `MCP::Tool` class in the same process, without a transport, has not been
checked here. Do not plan around it.

Costs of going through MCP for tools that live in the same app:

- A network hop (HTTP or a subprocess) on every tool call, even though the code is local.
- A server has to be running for specs, the console and the agent.
- Harder tests and traces: the model, the client, the server and the tool are four layers.
- Authentication and sessions to manage, which in-process calls skip.
- Results are wrapped in an MCP response and unwrapped again, so types like dates become text twice.
- If the logic itself lives in the `MCP::Tool` class, the agent path depends on MCP too.

When it is the right choice: the tools live in a different service than the agent, several unrelated
clients need the same tools, or you want to test the agent against exactly what Claude sees.

## How does an agent use tools from someone else's MCP server?

The agent acts as an MCP client. In RubyLLM 2.x you describe the server in a `RubyLLM::MCP`
subclass and attach it to the chat or agent:

```ruby
class Linear < RubyLLM::MCP
  url "https://mcp.linear.app/mcp"
  bearer_token { user.linear_token }
end

chat.with_mcp(Linear)
```

RubyLLM lists the server's tools and offers them to the model like any other tool, over Streamable HTTP
or a local `stdio` process. Hosted servers usually need OAuth or a bearer token.

This project does not use it yet (checked 2026-10-10): the course plan has the MCP server side in
Lesson 5 and no lesson where the agent calls an outside server. The `ai_shop_assistant` project
does this against Shopify's Catalog API.

## What is `AgentTools` for in the hand-written agent loop?

It is the bridge between the model and the Ruby tool classes. The model only reads and writes text, so
two translations are needed, and `AgentTools` does both:

1. **Code to model.** `definitions` turns the tool wrapper classes into the JSON `tools` list that
   Groq expects (name, description, argument schema). It is sent with every request.
2. **Model to code.** `run(name, arguments)` takes the tool name the model asked for (`"get_order"`) and
   its parsed arguments, finds the matching tool and executes it.

It is also the allowlist. The model can only run the tools passed to `AgentTools.new`; an invented name
such as `delete_order` returns an error hash and nothing runs.

```
AgentLoop            keeps the messages, repeats until the model answers
  ├─ LlmClient       talks to Groq
  └─ AgentTools      lists the tools and runs them by name
       └─ GetOrderTool → GetOrder → database
```

The wrapper classes (`RubyLLM::Tool`) stay the only place that describes a tool, so the hand-written
loop and `SupportAgent` send the model identical tool descriptions. Only the declarations are reused;
the loop itself is hand-written. `AgentLoop` parses the raw `arguments` JSON string before calling
`run`, so `AgentTools` only ever sees a hash.

## What is an agent loop, and how does it work?

An agent loop is a `loop` around the model call. The model can only read and write text, so it cannot
look anything up itself. It asks for a tool, the code runs it, and the result goes back to the model.
This repeats until the model answers in plain text.

The model has no memory between calls, so the loop keeps the `messages` array (the context) and sends
all of it every time. Each round adds to it:

1. The user question is added.
2. The model replies with `tool_calls` (a request, no `content`) or with `content` (the answer).
3. The model's reply is added to `messages`, so the history stays complete.
4. For each tool call, the code runs the tool and adds a `tool` message. Its `tool_call_id` links the
   result to the request it answers, and its `content` must be a string (`result.to_json`).
5. The model is called again with the longer `messages`.

```
ask model → tool_calls? → yes → run tools, add results to messages → ask model again
                        → no  → the content is the answer, stop
```

The model decides how many rounds happen, which is what makes it an agent and not a fixed pipeline. A
normal LLM call is one round trip. An agent loop is many, with tool results in between.

The stop condition is "the reply has no `tool_calls`". Because the model controls it, the loop needs
safety rails: a step limit (with a stop reason), unknown tool names, and arguments that are not valid
JSON. Without a step limit, a model that keeps asking for tools loops forever.

Frameworks such as RubyLLM run this same loop inside `chat.ask`. Writing it by hand once (Lesson 4)
shows what they hide.

## Are safety rails and guardrails the same thing?

They overlap and people use the words loosely, but in this project they mean two layers.

**Safety rails** are technical limits that keep the agent loop from breaking. They do not judge what
the agent says. Examples: a step limit so the loop cannot run forever, an unknown tool name returning an
error instead of running something, and invalid JSON arguments being caught instead of crashing the
run. They matter even if the model behaves well, because it can still make mechanical mistakes.

**Guardrails** is the broader industry term for rules about content and behavior:

- Input checks: block prompt injection, detect personal data, refuse off-topic requests.
- Output checks: do not leak another customer's data, do not promise a refund the policy does not allow.
- Action limits: a human approves risky actions (the approval screen for write tools, Lesson 9).
- Permissions: the allowlist of tools, and read tools kept apart from write tools.

| | Safety rails | Guardrails |
| --- | --- | --- |
| Question | Can the loop run without breaking? | Should the agent say or do this? |
| Example | Stop after 5 steps | A refund over a limit needs approval |
| Where | Inside `AgentLoop` | Around it, and in tools, prompts and approval screens |

Guardrails include some safety rails: the `AgentTools` allowlist is both a loop-robustness feature and a
guardrail on what the model may do.
