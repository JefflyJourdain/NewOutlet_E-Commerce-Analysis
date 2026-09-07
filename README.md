# 🛒 NewOutlet - Ecommerce Profitability Analytics

> **Status:** 🚧 completed

## Background & Business Context
This project moves beyond top-line revenue reporting to diagnose the underlying drivers of profitability for NewOutlet an ecommerce retailer answering questions like whether promotional discounting is actually paying for itself, which products in the catalog are worth keeping, why customers aren't buying more often within a given year. Each business question is treated as a standalone diagnostic, using tier, quadrant, and cohort-based frameworks rather than single-number KPIs.

---

## 📋 Table of Contents
- [Project Overview](#project-overview)
- [Key Findings & Strategic Insights](#key-findings--strategic-insights)
- [Dashboard Overview](#dashboard-overview)
- [Strategic Recommendations](#strategic-recommendations)
- [Tech Stack & Dataset](#tech-stack--dataset)
- [Project Structure](#project-structure)

---

## Project Overview

This project answers four business questions about an ecommerce retailer's pricing strategy, product portfolio, customer retention, and fulfillment operations, using tier, quadrant, and cohort-based frameworks instead of surface-level KPIs.

### Analytical Frameworks Applied

* **Discount Tier & Margin Waterfall Analysis:** Isolating whether promotional discounting drives incremental volume or simply erodes margin on sales that would have happened anyway.
* **Product Portfolio Quadrant Analysis:** Segmenting the catalog by volume and margin to separate products worth scaling from products worth cutting.
* **Cohort Repeat-Purchase Analysis:** Distinguishing lifetime retention from same-year purchase frequency to isolate whether a retention gap is behavioral or structural (natural replacement cycle).
* **Fulfillment Funnel Analysis (planned):** Tracking order-to-ship-to-delivery timing by product and region to locate where delays concentrate.

---

## 🔍 Key Findings & Strategic Insights

> _Detailed SQL queries, tier definitions, and calculations behind these findings are documented in the `analysis.md` file._

### 1. Financial Health & True Profitability
**Business question:** Does discounting actually pay for itself?

Discounting is not paying for itself. The moment any discount is introduced, order volume drops 68% (from 842k orders at 0% discount to 268k at 1-10%), then stays flat in the 64k-69k range through the 11-40% tiers, well below what would be needed to offset the price cut. Because volume never recovers, margin bleeds out steadily: gross margin falls from 58.5% at 0% to a trough of 30.7% in the 31-40% tier, and absolute profit collapses from $72.8M to just $2.0M over that same range. The 0% tier alone (842k orders, $72.8M profit) is the real engine of the business. A margin spike appears in the 41%+ tier, but it looks like a product-mix artifact rather than a pricing win, it's unlikely we're comparing like-for-like products at that depth of discount, so that tier needs a product-level audit before drawing conclusions from it.

### 2. Product Performance & Trends
**Business question:** Which products are driving volume vs. driving profit?

A quadrant analysis of the 83-product catalog shows a portfolio that's more bloated than it looks at first glance. 23 products fall into the "Dead Weight" (low volume, low margin), the single largest group, generating warehousing, supply chain, and marketing cost without a clear return; these are candidates for discontinuation or liquidation. Eighteen "Hidden Gems" (low volume, high margin) prove customers will pay a premium, so their low volume is more likely a visibility problem than a demand problem, making them strong candidates for bundling or cross-selling alongside the 24 "Hero" products (high volume, high margin) that already form a healthy, profitable core. The remaining 18 "Traffic Drivers" (high volume, low margin) are the most actionable group: given the discounting findings above, these are likely the same products sitting in the 11-30% discount tiers, and tightening their promotional spend is a plausible path to migrating them into the Hero quadrant.

### 3. Customer Behavior & Value
**Business question:** What is our customer repeat purchase rate?

The headline number depends entirely on the time window. Lifetime repeat purchase rate sits at 63.6% (customers who bought in 2022 and returned by 2024), showing real long-term product loyalty. But same-year repeat rate, the share of customers buying more than once within a single calendar year, has been flat at 25.9-26.9% across 2022, 2023, and 2024. That plateau points to two things: current post-purchase nurture campaigns (generic "buy again" emails, 30-day retargeting) have hit a ceiling, and the product category likely has a replacement cycle longer than 12 months, so customers genuinely don't need to reorder that fast. The fix isn't more frequency pressure, it's shifting post-purchase marketing toward lifecycle triggers: cross-selling Hidden Gems, seasonal refreshes, tiered loyalty, rather than fighting the natural usage cycle.

---

## Dashboard Overview

_Global filters for Year, Region, and Sales Channel are applied across the report._

### E-commerce Company Performance Report
Single-page executive view combining top-line KPIs, profit and order trends, category-level revenue/profit, and returns tracking.

<img width="562" height="346" alt="{459AB609-9220-4B77-8597-6EECAD9A4622}" src="https://github.com/user-attachments/assets/21f3c8d9-7062-4f9c-8a73-f8637689fca5" />


**Key Insights:**
* **Orders are trending down sharply** across the period shown, from a peak of 1,199 down to 401, even as profit is up 43.6% year-over-year and COGS up 39.7%, a gap worth digging into (fewer but larger orders vs. a seasonality effect the trend line doesn't capture).
* **Return rate is the one KPI moving the wrong way:** 13.18%, up 12.4% month-over-month and 19.1% year-over-year.
* **Office leads the category mix** on both revenue and profit, ahead of Storage, Kitchen, and Bedroom, consistent with Office Chairs Model C2 showing up among the top 3 products.
* **Margin has held roughly flat** (57.46%, -0.5% MoM, +1.8% YoY) despite the swings in orders, revenue, and COGS, so overall profitability hasn't been dragged down yet.


---

## 🎯 Strategic Recommendations

| Priority | Action | Owner | Expected Impact | Metric to Track |
| :--- | :--- | :--- | :--- | :--- |
| **P0** | Cut broad discounting in the 11-30% range, where volume gains never offset margin loss. | Pricing / Revenue | Recovered margin without a corresponding volume loss. | Gross margin % and profit by discount tier |
| **P0** | Audit product mix inside the 41%+ discount tier before treating its margin spike as a signal. | Pricing / Merchandising | Accurate read on whether deep discounts ever work. | Product/category composition of the 41%+ tier |
| **P1** | Discontinue or liquidate the 23 "Dead Weight" SKUs. | Merchandising / Supply Chain | Lower warehousing and marketing spend on non-performing SKUs. | SKU count & holding cost in Dead Weight quadrant |
| **P1** | Bundle or cross-sell the 18 "Hidden Gems" alongside "Hero" products. | Merchandising / Marketing | Volume growth on high-margin products without discounting. | Hidden Gem order volume, bundle attach rate |
| **P1** | Tighten discounts on "Traffic Driver" products to push them toward the Hero quadrant. | Pricing / Merchandising | Higher margin on already-high-volume products. | Traffic Driver margin %, quadrant migration |
| **P2** | Replace generic "buy again" prompts with lifecycle-based triggers (seasonal, cross-sell, loyalty tiers). | Marketing / CX | Lift in same-year repeat rate above the 26% plateau. | Same-year repeat purchase rate |

---

## Tech Stack & Dataset

| Tool | Purpose |
|------|---------|
| **SQL Server (T-SQL)**   | Data cleaning, schema design, Data analysis & insights |
| **Python (pandas)**   | Extract and load data using advanced scripts |
| **Power BI** | Visualitation and dashboard creation |

**Source Data:** Based on a synthetic dataset made by myself can be found on  kaggle(https://www.kaggle.com/datasets/kaisersafdf/messy-e-ccomerce-dataset) 


