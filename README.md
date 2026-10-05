# AI Support Engineer: a production-style AI agent in Ruby on Rails

A support agent that investigates customer problems, searches company policies, checks real order data, and takes safe actions only with human approval.

> **Status:** early development (Lesson 1 of 14). This is a learning project, built step by step, not a finished product. The plan below describes where it is going, not what works today.

## The problem

Most AI support demos are chatbots that sound confident and guess. A real support case needs more than a fluent answer:

> "My order #1042 has not arrived and it has been two weeks. If it is lost, please send a replacement."

To answer this correctly, a system has to look up the order, check the shipment, find the lost-package rule in the shipping policy, decide whether a replacement is allowed, and get a person to approve it before anything is changed. Then it has to cite where each fact came from.

This project builds that system, and measures whether it gets it right.

## What it will do

An agent that reasons and uses tools instead of answering from memory:

1. **Route:** decide what the message needs (order data, policy, or both).
2. **Act:** call read tools such as `get_order` and `get_shipment`.
3. **Retrieve:** search policy documents (RAG) for the relevant rule.
4. **Decide:** a replacement or refund is a write action, so it needs approval.
5. **Ask for approval:** a support person sees the proposed action with the evidence.
6. **Execute and audit:** the action runs and is written to an audit log.
7. **Answer:** the customer gets a reply that cites the order status and the policy section.

Every step is traced, and each scenario is also an eval case with a known correct answer.

### Tools and permissions

Tools are plain Ruby classes. The agent and the MCP server only wrap them, so the same tools work from the chat, the approval screen and Claude.

| Tool | Type | Rule |
| --- | --- | --- |
| `get_order`, `get_shipment`, `get_customer`, `search_orders`, `search_policies` | Read | Automatic |
| `update_address` | Write, low risk | Automatic after a policy check |
| `create_return`, `create_replacement_order` | Write, high risk | Human approval |
| `issue_refund`, `cancel_order` | Write, high risk | Human approval and confirmation |

## Tech stack

| Area | Choice |
| --- | --- |
| App | Rails 8, Hotwire, Tailwind CSS |
| Database | PostgreSQL, pgvector (added in the RAG lesson) |
| LLM library and provider | RubyLLM, Groq (free tier) |
| Embeddings | Ollama (local) |
| MCP | Official MCP Ruby SDK |
| Observability | OpenTelemetry, Langfuse |
| Evals | eval-ruby, rspec-agents |

Gems are added in the lesson that needs them, not all at once. All LLM calls will go through one small `LlmClient` class, so changing provider is a config change.

## Roadmap

Three milestones, 14 lessons. Each lesson changes the same application and gets a Git tag (`lesson-01`, `lesson-02`, ...).

**Milestone 1: a working support agent**
1. A normal Rails app with real and planted data (no AI yet) **(in progress)**
2. First LLM call and structured output
3. Tool calling with read tools
4. The agent loop, written by hand
5. MCP server and Claude connector
6. RAG over policy documents

**Milestone 2: quality and safety**

7. Routing: tools, RAG or both
8. Hybrid search and reranking
9. Write tools, permissions and human approval
10. Evals
11. Observability and cost tracking

**Milestone 3: advanced**

12. Memory and context engineering
13. Multi-agent orchestration
14. Feedback loop and deployment

## Data

Real public data makes the app believable, and planted scenarios give every eval a known answer.

- **Base data:** the Brazilian E-Commerce Public Dataset by Olist (Kaggle): customers, orders, items, products and payments.
- **Planted scenarios:** added by a seed script with a fixed random seed, so everyone gets the same data. First set: delayed shipment, lost package, return window closed, final sale item, duplicate charge.
- **Policies:** written by hand, with deliberate exceptions, because exceptions are where weak retrieval fails.

Dataset files are not committed. They live in `data/` (git-ignored) and are downloaded separately. Check each dataset's license on its own page before using it.

**Attribution:** the base data is the [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce), licensed under [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/). It is used here for non-commercial learning only. This repository contains the import and seed code, not the data or a database built from it.

Customer messages for routing and evals (from Lesson 7) come from the [Bitext customer support dataset](https://huggingface.co/datasets/bitext/Bitext-customer-support-llm-chatbot-training-dataset), licensed under [CDLA-Sharing-1.0](https://cdla.dev/sharing-1-0/). The data file is not included here either.

## Getting started

Requirements: Ruby, PostgreSQL, and the Ruby version set for this app.

```bash
bundle install
bin/rails db:create
bin/rails db:migrate
bin/dev
```

The dataset import task and the scenario seed script are part of Lesson 1 and do not exist yet.

## Scope

This is a learning project about building a reliable AI agent, not a complete support product. Real Shopify or BigCommerce integration, multi-modal input and new eval tooling are out of scope for now.

## More

The full plan, with architecture, gems by lesson, data mapping and the evaluation plan, is in [docs/PROJECT_PLAN.md](docs/PROJECT_PLAN.md).
