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
