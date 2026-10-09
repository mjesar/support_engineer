# AI Support Engineer: Project and Course Plan

Last updated: 2026-10-06

## 1. Overview

The AI Support Engineer is a Ruby on Rails system that investigates customer problems, searches company knowledge, checks real order data, and takes safe actions with human approval. It is not a chatbot: it reasons, uses tools, and proves its answers.

The project is also the course **Production AI with Rails**. Every lesson changes the same application, from a normal Rails app to a production-style AI agent system.

**Why this project:**

- It covers the full AI engineering lifecycle: tool calling, agents, MCP, RAG, routing, permissions, evals, observability and multi-agent.
- It uses Rails and e-commerce experience as an advantage in every lesson.
- Customer support is one of the most common business uses of AI, so the demo is easy to understand.
- No complete, end-to-end production AI course exists for Rails today.

**Positioning:** Learn AI engineering by building a production-style AI support system in Ruby on Rails, step by step.

## 2. Example scenario

A customer writes: *"My order #1042 has not arrived and it has been two weeks. If it is lost, please send a replacement."*

1. **Route:** the agent decides this needs order data and the shipping policy.
2. **Act:** it calls `get_order(1042)` and `get_shipment(1042)`.
3. **Observe:** the shipment was sent 14 days ago, and the carrier status is "exception".
4. **Retrieve:** it searches the shipping policy and finds the rule for lost packages.
5. **Decide:** a replacement is allowed, but it is a write action, so it needs approval.
6. **Ask for approval:** a support person sees the proposed action with the evidence and approves it.
7. **Execute:** `create_replacement_order(1042)` runs, and the action is written to the audit log.
8. **Answer:** the customer gets a reply that cites the order status and the policy section.

Every step is traced, and this exact case is also an eval case with a known correct answer.

## 3. Architecture

```
  Customer chat        Approval screen        Claude via MCP
  (Hotwire)            (support staff)        (same tools)
        |                     |                     |
        +---------------------+---------------------+
                              |
                +-----------------------------+
                |  Agent (RubyLLM + Groq)     |      Reliability (around everything)
                |  Router -> Agent loop       | ---  - Evals (planted scenarios)
                +-----------------------------+      - Tracing (OpenTelemetry -> Langfuse)
                              |                      - Audit log (every write action)
        +---------------------+---------------------+  - Guardrails (allowlists, limits)
        |                     |                     |
   Read tools           Policy search          Write tools
   (orders,             (RAG, hybrid,          (run only after
    shipments)           rerank)                approval)
        |                     |
   PostgreSQL            pgvector
   (orders, customers,   (policy chunks
    shipments)            and embeddings)
```

All three interfaces use the same agent and the same Ruby tools. Only write tools wait for a person to approve.

## 4. Tech stack

The rule is compose, do not rebuild: use existing libraries and spend the time on the system design.

| Area | Choice | Why |
| --- | --- | --- |
| App | Rails 8, Hotwire (Turbo, Stimulus) | Turbo Streams for streaming answers |
| Database | PostgreSQL + pgvector | Data, full-text search and vectors in one place |
| Background jobs | Solid Queue (Rails 8 default) *or* Sidekiq | See decision below |
| Cache | Solid Cache (Rails 8 default) *or* Redis | See decision below |
| LLM library | RubyLLM | Most popular Ruby LLM library; tools, agents, Rails integration |
| LLM provider | Groq (free tier) | Small model for routing and grading, larger model for answers |
| Embeddings | Ollama (local) | Free, no rate limits |
| MCP | Official MCP Ruby SDK, Streamable HTTP | Same tools usable from Claude |
| Observability | OpenTelemetry + Langfuse | Existing tools, no custom tracing |
| Evals | eval-ruby, rspec-agents | Existing Ruby gems for RAG and agent evals |
| Tests | RSpec | Normal code tests |

All LLM calls go through one small `LlmClient` class, so switching between Groq, Gemini or Claude is a config change.

**Exception:** in Lesson 4 the agent loop is written by hand, without any framework, so the reasoning loop is understood before RubyLLM is used for it.

**Decision to make:** Solid Queue + Solid Cache (no Redis, simpler for learners) or Sidekiq + Redis (common in companies). Suggested: Rails 8 defaults for the course, with a short note on Sidekiq as the alternative.

## 5. Gems by lesson

Add each gem only in the lesson that needs it. Check the latest version and maintenance status when adding.

| Lesson | Gem | Purpose |
| --- | --- | --- |
| 1 | `rails` 8, `pg` | App and database |
| 1 | `faker` | Generated names, emails and scenarios |
| 1 | `csv` | Reading dataset files (must be in the Gemfile since Ruby 3.4) |
| 1 | `rspec-rails`, `factory_bot_rails` | Tests |
| 2 to 4 | `ruby_llm` | LLM calls, structured output, tools |
| 2 to 4 | `vcr`, `webmock` | Record LLM responses so tests do not call the API every time |
| 5 | `mcp` (official MCP Ruby SDK) | MCP server |
| 6 | `neighbor` | pgvector support in ActiveRecord |
| 6 | none | Embeddings through RubyLLM with Ollama |
| 8 | none | Full-text search in plain SQL (clearer for learning) |
| 9 | built in | Rails 8 authentication for the approval screen |
| 10 | `eval-ruby`, `rspec-agents` | Evals |
| 11 | `opentelemetry-sdk`, `opentelemetry-exporter-otlp`, `opentelemetry-instrumentation-ruby_llm` | Tracing, sent to Langfuse |

## 6. Data plan

Real public data makes the app believable; planted scenarios give every eval a known correct answer.

| Data | Source | Notes |
| --- | --- | --- |
| Orders, customers, payments, delivery dates | Brazilian E-Commerce Public Dataset by Olist (Kaggle) | Has estimated and actual delivery dates, so real delays exist |
| Customer messages by intent | Bitext customer support dataset (Hugging Face) | Labeled intents for routing and evals |
| Real customer phrasing | Customer Support on Twitter (Kaggle) | Messy, realistic language |
| Product names and text | Amazon Reviews 2023 (Hugging Face) or mock.shop | Olist has categories only |
| Policies and guides | Written by hand, with LLM help | Real companies' policies are copyrighted |
| Special cases | Planted by a seed script | Known answers for evals |

**Olist file to model mapping (check real column names after download):**

| Olist file | Model | Notes |
| --- | --- | --- |
| customers | `Customer` | Add generated names and emails |
| orders | `Order` | Status, purchase date, estimated and actual delivery dates |
| order_items | `OrderItem` | Product, price, freight value |
| products + category translation | `Product` | English categories; generate product names |
| payments | `Payment` | Useful for the duplicate charge scenario |
| reviews | `Review` | Optional (Portuguese text) |
| sellers | skipped for now | Not needed for support |
| none | `Shipment` | Generated from the order's delivery dates |
| none | `Return`, `Refund`, `SupportTicket` | Generated with the scenarios |

**Planted scenarios (first set):**

- Delayed shipment: shipped 12+ days ago, no delivery
- Lost package: carrier status "exception"
- Return window closed: delivered 40 days ago, policy allows 30
- Final sale item: cannot be returned
- Duplicate charge: two payments for one order

**Policy documents** should be long, with sections and deliberate exceptions (final sale items, free shipping except furniture, 45 days for members). Exceptions are where weak RAG fails.

**Rules:**

- Check each dataset's license on its page before use.
- Olist is CC BY-NC-SA 4.0 (checked 2026-10-06): credit Olist and link the dataset wherever it is used, non-commercial use only, derived data shared under the same license. So: never commit the CSVs or a database dump built from them, and keep the import step swappable in case the course is ever sold (generated data would replace Olist).
- Never commit dataset files; keep them in `data/` (in `.gitignore`) and document the download steps.
- Use a fixed random seed (`Faker::Config.random = Random.new(42)`) so every learner gets the same data.
- Start small (500 customers, 2,000 orders) and scale later.

## 7. Tools and permissions

Every tool has a risk level, and the risk level decides whether the agent may run it alone.

| Tool | Type | Risk level | Rule |
| --- | --- | --- | --- |
| `get_order` | Read | Read | Automatic |
| `get_shipment` | Read | Read | Automatic |
| `get_customer` | Read | Read | Automatic |
| `search_orders` | Read | Read | Automatic |
| `search_policies` | Read (RAG) | Read | Automatic |
| `update_address` | Write | Low risk | Automatic after a policy check (only before shipping) |
| `create_return` | Write | High risk | Human approval |
| `create_replacement_order` | Write | High risk | Human approval |
| `issue_refund` | Write | High risk | Human approval + confirmation |
| `cancel_order` | Write | High risk | Human approval + confirmation |

**Safety rules:**

- Tools are plain Ruby classes; MCP and the agent only wrap them.
- An allowlist defines which tools each agent can see.
- Every write action is saved in an audit log (who, what, when, approved by).
- Customer data shown to the model is limited to what the task needs.
- No tool runs raw SQL or opens arbitrary URLs.

## 8. Milestones and lessons

Three milestones, 14 lessons. Each milestone is portfolio-ready on its own. Milestone 2 does not start until Milestone 1 is finished, pushed and posted.

**Milestone 1: a working support agent (about 4 to 6 weeks)**

1. A normal Rails app with real and planted data (no AI yet)
2. First LLM call and structured output (the model returns JSON, Rails decides)
3. Tool calling with read tools
4. The agent loop, written by hand (context, reason, act, observe)
5. MCP server and Claude connector
6. RAG over policy documents (chunking, embeddings, pgvector)

**Milestone 2: quality and safety**

7. Routing: tools, RAG or both
8. Hybrid search and reranking
9. Write tools, permissions and human approval
10. Evals with eval-ruby and rspec-agents
11. Observability with OpenTelemetry and Langfuse, plus cost tracking

**Milestone 3: advanced**

12. Memory and context engineering
13. Multi-agent orchestration (and when it is not worth it, measured with evals)
14. Feedback loop and deployment

**Every lesson includes:** the concept in simple words, the build steps, what broke, proof (an eval result or trace), a Git tag (`lesson-01`, `lesson-02`, ...), a DEV.to post and a LinkedIn post.

## 9. Evaluation plan

Eval cases come from the planted scenarios, so every case has a known correct answer. Each case runs several times, because one passing run proves little.

```yaml
- message: "Where is my order #1042? It has been 2 weeks!"
  scenario: delayed_shipment
  expected_tools: [get_order, get_shipment]
  expected_sources: [shipping_policy]
  expected_action: create_replacement_order (with approval)
  runs: 5
  pass_rate: 0.8
```

**What is measured:**

- Tool selection and arguments (deterministic, no LLM judge)
- Forbidden actions never run without approval (deterministic)
- Numbers in the answer match tool results (deterministic grounding check)
- Retrieval quality: Precision@K, MRR (eval-ruby)
- Faithfulness to the policy text (eval-ruby, LLM judge)
- Task completion over a conversation (rspec-agents)
- Consistency across runs, latency and cost

**Rule:** deterministic checks first; an LLM judge only for things code cannot check.

## 10. Scope rules

The project choice is locked. New project plans from other tools are not considered; other tools are used only for help with specific lessons.

**Decided:**

- One application, changed lesson by lesson, never separate toy examples.
- Build the agent loop by hand once (Lesson 4), then use RubyLLM.
- MCP comes before the full agent features, reusing the same Ruby tools.
- Use existing gems for evals and observability; do not build new ones.
- Learning mode: write the code yourself, with AI tools explaining and reviewing.

**Out of scope for now:**

- A new eval gem (rspec-agents and eval-ruby already exist)
- Multi-modal input (images, uploaded PDFs)
- Real Shopify or BigCommerce integration (possible later as an extra MCP adapter)
- Other project ideas (product research agent, merchant profit analyst, GEO embedded app): backlog

**Before building any new idea:** spend 15 minutes searching GitHub and RubyGems for existing tools.

## 11. Open questions

- [ ] Final project and repo name (check GitHub and RubyGems first)
- [ ] Solid Queue + Solid Cache, or Sidekiq + Redis
- [ ] Olist as the base data, or fully generated data only
- [ ] Licenses of the Twitter support dataset checked (Olist done: CC BY-NC-SA 4.0; Bitext done: CDLA-Sharing-1.0, text at https://cdla.dev/sharing-1-0/, use and results are unrestricted, publishing the data itself requires the same license and credit)
- [ ] Groq free-tier limits checked in the Groq console
- [x] RubyLLM support for Groq confirmed (2026-10-08): no native provider, use the OpenAI-compatible route (`openai_api_base` set to Groq's OpenAI endpoint, `provider: :openai`, `assume_model_exists: true`, per the RubyLLM docs). Verified in the console on 2026-10-09 with ruby_llm 2.1.0: also pass `protocol: :chat_completions`, because 2.x defaults OpenAI to the Responses API and Groq rejects its `include` field. `llama-3.3-70b-versatile` is gone from Groq; `openai/gpt-oss-120b` answers. Whether a given Groq model supports structured output is tested in the console in lesson 2
- [ ] RubyLLM support for Ollama embeddings confirmed
- [ ] Blog platform chosen (DEV.to suggested)

## 12. Current step: Lesson 1 checklist

- [x] Create the app: `rails new <name> --database=postgresql --css=tailwind`
- [x] Add `data/` to `.gitignore`
- [x] Download the Olist dataset into `data/olist/` and check its license
- [x] Note the column names of `orders`, `order_items`, `customers` and `products`
- [x] Write the migrations for `Customer`, `Product`, `Order`, `OrderItem`, `Payment`, `Shipment`
- [ ] Write the import task (`bin/rails data:import_olist`): written and tested on a sample, batching and a full run still to do
- [x] Write the scenario seed script with a fixed random seed (`bin/rails data:plant_scenarios`)
- [ ] Tag `lesson-01`

Detailed progress, decisions and measured results: [lessons/01-data-model-and-import.md](lessons/01-data-model-and-import.md).
