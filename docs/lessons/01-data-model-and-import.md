# Lesson 1: a normal Rails app with real data

No AI yet. This lesson builds the data the agent will later investigate: customers, orders,
payments and shipments, loaded from a real public dataset. Every later lesson changes this same app.

Last updated: 2026-10-07

## Status

- [x] App, gems (RSpec, FactoryBot, Faker, csv)
- [x] Six tables, models and associations (see [DATA_MODEL.md](../DATA_MODEL.md))
- [x] Data model diagram
- [x] Import for customers, products, orders, order items and payments, tested with a 200 customer sample
- [x] All five sections imported in batches (about 70 minutes down to about 3)
- [x] Full import run, totals checked against the Olist files
- [x] Shipments generated, plus five planted scenarios: delayed shipment, lost package, return window
      closed, final sale item and duplicate charge
- [x] Specs and factories for every model, and for the scenarios task
- [x] README: how to run the import and the scenarios
- [x] Clean `db:reset` run from scratch: import, scenarios and specs all pass
- [ ] Tag `lesson-01` after the merge

## What was built

`bin/rails data:import_olist` (in `lib/tasks/data.rake`) reads the Olist CSV files from `data/olist/` and
fills the tables in dependency order: customers, products, orders, then order items and payments.
Names, emails and product names are generated, because Olist has none.

```
LIMIT=200 bin/rails data:import_olist   # a small, consistent sample in about half a minute
bin/rails data:import_olist             # everything, about 3 minutes
bin/rails data:plant_scenarios          # shipments for every order, then the five planted scenarios
```

`LIMIT` applies to customers only. Everything below customers follows on its own: an order whose
customer was not loaded is skipped, and so are the items and payments of skipped orders. Each step prints
how many rows it kept and how many it skipped, so the totals can be checked against the files.

## Planted scenarios

Real data has no cases where we know the right answer, and an eval needs one. `bin/rails data:plant_scenarios`
(in `lib/tasks/scenarios.rake`) first generates a shipment for every order that was handed to a carrier, then
edits five orders so each tells one story. These are the golden cases the later lessons test the agent against.

| Scenario | What is planted | Correct answer for the agent |
| --- | --- | --- |
| Delayed shipment | Shipped 13 days ago, shipment `in_transit`, last scan 11 days ago | Apologize, share tracking, wait |
| Lost package | Shipped 21 days ago, shipment `exception`, last scan 16 days ago | Offer a replacement (needs approval) |
| Return window closed | Delivered 40 days ago, the policy allows 30 | Refuse the return |
| Final sale item | Delivered 5 days ago, but the product has `final_sale: true` | Refuse the return |
| Duplicate charge | Two identical payments on one order | Refund one (needs approval) |

The five orders are the first five (by id) that have a shipment. That rule does not depend on the integer
ids, which change on every import, so reruns always plant on the same orders. The task prints the order id of
each scenario, and running it twice gives the same result (the duplicate payment is not added again).
A product marked final sale is final sale on every order that contains it, which is fine for the evals.

## Decisions and why

| Decision | Why |
| --- | --- |
| Integer ids plus an `olist_*_id` column | Olist ids are 32 character hex strings. Integers are smaller and read naturally. The Olist id is only for matching rows during import, so it has a unique index. |
| One `Customer` per real person | Olist makes a new `customer_id` for every order. The stable `customer_unique_id` identifies the person, so `customer.orders` shows a real history. The import keeps a lookup from each per-order id to the person. |
| Unknown values stay `nil`, never `0` | A missing weight stored as 0 would make the agent say an item weighs nothing. `nil` lets it say "not recorded". Rails casts the CSV strings, so no `.to_i` is needed. |
| Emails are name plus a counter on reserved domains | `brittany.klocko.7@example.org`. The counter makes every email unique even when names repeat, and `example.com`, `.org` and `.net` can never reach a real mailbox, which matters once the agent can send email. |
| Category translations come from the Olist file, not an AI | A fixed lookup file gives the same result every run, costs nothing and keeps the data reproducible. Categories missing from it keep their Portuguese name. |
| Money is `decimal(10, 2)` | Floats cannot store 58.90 exactly, which is a real bug when computing refunds. |
| The database enforces the rules | `null: false`, unique indexes and foreign keys stop bad rows even if a script or a console typo tries to create them. |
| Batch inserts with `insert_all!` | One query per 1,000 rows instead of one per row. The bang version raises on a duplicate instead of silently skipping it, so a bad dataset cannot lose rows unnoticed. It skips validations and callbacks, which is fine while the models have none. |
| Fixed random seed | `Faker::Config.random = Random.new(42)` gives everyone the same names, which evals will rely on. |

## What broke

- **The first CSV column had a hidden character.** The category translation file starts with a byte
  order mark. Reading it with `encoding: "bom|utf-8"` fixes the column name.
- **A column called `sequence` clashed with FactoryBot.** `sequence` is a keyword there, so the generated
  factory failed with "wrong number of arguments". The fix is `add_attribute(:sequence) { 1 }`.
- **`delete_all` does not reset ids.** After several test runs the first customer had id 46986. The
  ids are harmless, but evals must find records by content or Olist id, never by a fixed integer id.
- **Importing one row at a time was far too slow.** Each `create!` is its own database round trip.
  Products took 5 minutes 22 seconds, and the full import of the other four took about an hour. Batching
  with `insert_all!` brought products to 17 seconds and the whole import to about 3 minutes, with identical counts.
- **The import failed once shipments existed.** It cleared `orders` while `shipments` still pointed at them,
  and the foreign key refused. Child tables are now cleared first, shipments before orders.

## Proof

Measured on 2026-10-06 and 2026-10-07.

| Step | Result |
| --- | --- |
| Full import | 96,096 customers (from 99,441 rows), 32,951 products, 99,441 orders, 112,650 order items, 103,886 payments, nothing skipped |
| Sample run, `LIMIT=200` | 200 customers, 200 orders, 226 order items, 209 payments |
| Sample run honesty check | orders 200 + skipped 99,241 = 99,441 rows; items 226 + 112,424 = 112,650; payments 209 + 103,677 = 103,886 |
| Import time, one row at a time | about 70 minutes (customers 14 min, orders 16 min, items 25 min, payments 14 min) |
| Import time, batches of 1,000 | about 3 minutes (customers 61 s, orders 70 s, items 21 s, payments 18 s) |
| Shipments generated | 97,658 (orders that never reached a carrier have none) |
| Specs | 20 examples, 0 failures; rubocop clean |
| Clean run from scratch | `db:reset`, import (about 3 minutes), `plant_scenarios`, specs: same totals, scenarios on orders 1 to 5 |

Known trade-offs: the import is not wrapped in a transaction (a crash leaves partial data, and rerunning
clears and reloads everything), and it has no automated test of its own, only the totals above.

## Where each piece lives

- Tables and relations: [DATA_MODEL.md](../DATA_MODEL.md)
- Import code: `lib/tasks/data.rake`
- Shipments and planted scenarios: `lib/tasks/scenarios.rake`, tested in `spec/tasks/scenarios_spec.rb`
- Dataset files: `data/` (git-ignored, see the README for the source and license)
