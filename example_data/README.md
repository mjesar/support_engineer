# example_data

Header-only copies of the dataset files this project reads. Each file has the real column names and no rows. They show the expected layout and file names, so you can see what to download and where it goes.

The real data is not in this repository (see licenses below). Put it in `data/`, which is git-ignored, using the same structure:

```
data/
  olist/    the 9 CSV files from the Olist dataset, original file names
  bitext/   customer_support.csv
```

## Olist (used from Lesson 1)

Brazilian E-Commerce Public Dataset by Olist, license CC BY-NC-SA 4.0.
https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

1. Sign in to Kaggle and download the dataset.
2. Unzip it into `data/olist/`. Keep the original file names.

## Bitext (used from Lesson 7)

Bitext customer support dataset, license CDLA-Sharing-1.0.
https://huggingface.co/datasets/bitext/Bitext-customer-support-llm-chatbot-training-dataset

1. Download the CSV from the dataset page (Files and versions).
2. Save it as `data/bitext/customer_support.csv`. The original file name is long
   (`Bitext_Sample_Customer_Support_Training_Dataset_27K_responses-v11.csv`), so it is renamed.

## Notes

- The product category translation file has an invisible byte order mark in the real download. Read it with the `bom|utf-8` encoding. The header-only copy here does not include it.
- Do not commit the real files or a database built from them.
