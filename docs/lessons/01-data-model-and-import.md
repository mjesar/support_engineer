# Lesson 1: a normal Rails app with real data

No AI yet. This lesson builds the data the agent will later investigate: customers, orders,
payments and shipments, loaded from a real public dataset. Every later lesson changes this same app.

Last updated: 2026-10-07

## Status

- [x] App, gems (RSpec, FactoryBot, Faker, csv)
- [x] Six tables, models and associations (see [DATA_MODEL.md](../DATA_MODEL.md))
- [x] Data model diagram
- [x] Import for customers, products, orders, order items and payments, tested with a 200 customer sample
- [x] Products imported in batches (5 min 22 s down to 17 s)
- [ ] Batch the other four sections (customers, orders, items, payments)
- [ ] Run the full import once, without a limit, and check the totals
- [ ] Scenario seed script: shipments, plus delayed shipment, lost package, return window closed,
      final sale item and duplicate charge
- [ ] README: how to run the import
- [ ] Clean `db:reset` run from scratch, then tag `lesson-01`

## What was built

`bin/rails data:import_olist` (in `lib/tasks/data.rake`) reads the Olist CSV files from `data/olist/` and
fills the tables in dependency order: customers, products, orders, then order items and payments.
Names, emails and product names are generated, because Olist has none.

```
LIMIT=200 bin/rails data:import_olist   # a small, consistent sample in about half a minute
bin/rails data:import_olist             # everything
```

`LIMIT` applies to customers only. Everything below customers follows on its own: an order whose
customer was not loaded is skipped, and so are the items and payments of skipped orders. Each step prints
how many rows it kept and how many it skipped, so the totals can be checked against the files.

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
| Fixed random seed | `Faker::Config.random = Random.new(42)` gives everyone the same names, which evals will rely on. |

## What broke

- **The first CSV column had a hidden character.** The category translation file starts with a byte
  order mark. Reading it with `encoding: "bom|utf-8"` fixes the column name.
- **A column called `sequence` clashed with FactoryBot.** `sequence` is a keyword there, so the generated
  factory failed with "wrong number of arguments". The fix is `add_attribute(:sequence) { 1 }`.
- **`delete_all` does not reset ids.** After several test runs the first customer had id 46986. The
  ids are harmless, but evals must find records by content or Olist id, never by a fixed integer id.
- **Importing products one at a time took 5 minutes 22 seconds.** Each `create!` is its own database
  round trip. Batching with `insert_all` brought it to 17 seconds with identical counts.

## Proof

Measured on 2026-10-06 and 2026-10-07.

| Step | Result |
| --- | --- |
| Customers, full file | 96,096 people from 99,441 rows, 96,096 distinct emails |
| Products, full file | 32,951 |
| Sample run, `LIMIT=200` | 200 customers, 200 orders, 226 order items, 209 payments |
| Sample run honesty check | orders 200 + skipped 99,241 = 99,441 rows; items 226 + 112,424 = 112,650; payments 209 + 103,677 = 103,886 |
| Products import time | 5 min 22 s one by one, 17 s in batches of 1,000 |

Expected for the full import, not yet run: 99,441 orders, 112,650 order items and 103,886 payments.

## Where each piece lives

- Tables and relations: [DATA_MODEL.md](../DATA_MODEL.md)
- Import code: `lib/tasks/data.rake`
- Dataset files: `data/` (git-ignored, see the README for the source and license)
