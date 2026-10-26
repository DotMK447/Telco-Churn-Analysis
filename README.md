# Telco Customer Churn Analysis

A MySQL analysis on Telco Customer Churn dataset, Identifying the cause of churn by building a hypothesis driven investigation which customer segments drive churn, rather than open-ended exploration.  

## Business Context

**Company:** Fictional telecom provider (California), offering home phone and internet service.
**Dataset:** 7,043 customers, single point-in-time snapshot (no historical/trend data).
**Stakeholder:** Retention manager, deciding how to prioritize limited retention budget and effort.
**Business question:** Which customer segments show the highest churn, and what's actually driving it?

## Business questions

- How does churn vary by contract type and customer tenure?
- Are customers with more add-on services less likely to churn?
- Does churn differ between fiber-optic and DSL customers?
- Among senior customers, how is churn associated with TechSupport and monthly charges?
- Is churn higher for manual payment methods, and does the pattern differ by payment type?

## Dataset

The analysis uses the [Telco Customer Churn](https://www.kaggle.com/datasets/blastchar/telco-customer-churn) CSV file. The SQL script expects the file to be available locally; it does not download the dataset.

The dataset includes customer characteristics, subscribed services, contract and payment details, monthly and total charges, tenure, a churn indicator, and other customer datas. See the CSV's original source and terms before redistributing it with this repository.

## Tools

- **MySQL 8.0** — all analysis, from data cleaning through hypothesis testing, done in SQL.

## Repository contents

```text
telco-churn-analysis/
├── README.md
└── telco_churn_analysis.sql
```

## How to run

1. Use MySQL with support for the SQL features in the script, including window functions (MySQL 8.0 or later).
2. Save the CSV on your computer.
3. Open `sql/telco_churn_analysis.sql` and replace the example path in `LOAD DATA LOCAL INFILE` with the CSV's location. For example:

   ```sql
   LOAD DATA LOCAL INFILE 'C:/path/to/telco_churn.csv'
   ```

4. Make sure `LOAD DATA LOCAL INFILE` is allowed by both the MySQL server and the client you use. The script includes a server-side setting that may require administrator privileges; client configuration is separate.
5. Run the script from the beginning through the end.

**Reset behavior:** each full run drops and recreates the `customers` table before importing the CSV. This makes a full rerun start cleanly, but permanently deletes any existing data in that table. Back up anything you need before running it. The script does not drop the whole database.

## Analysis, hypothesis, key findings, and conclusions

The analysis tests 7 hypotheses. The findings below describe associations in this dataset; they do not establish that one factor caused churn.

### H1. Contract and tenure

**Hypotheses**

- **H1a — Contract commitment:** Month-to-month customers churn more because they can leave without a long-term commitment.
- **H1b — Customer tenure:** Churn among month-to-month customers is highest early in tenure and declines as customers stay longer.

**Findings**
- Month-to-month customers have a reported churn rate of about 43% and account for about 88.55% of churned customers.
- Within the month-to-month group, churn falls from about 55.20% for customers with 0–6 months of tenure to 30.86% for those with 25 or more months.
- Among customers with 25 or more months of tenure, the reported churn rates are 30.86% for month-to-month, 11.89% for one-year, and 3.12% for two-year contracts.

**Conclusion: Both patterns are supported by the comparisons.** These are consistent with both tenure and contract type being associated with churn.

**Implication:** consider testing early-tenure onboarding and contract-conversion offers. Measure retention alongside the cost of any discounts.

### H2. Add-on services

**Hypothesis:** Customers with more add-on services are less likely to churn because they may be more connected to the company's services.

- Among customers with internet service(78.33% of total customers), the reported churn rate declines from 52.24% for customers with no counted add-ons to 5.28% for those with six.
- Among customers with internet service and 25 or more months of tenure, the reported rate declines from 25.00% to 5.04% across those groups.
- Average add-on ownership also rises with tenure, so tenure may explain part of the raw association.

**Conclusion: The association is supported, but it weakens after comparing customers with longer tenure.**

**Implication:** the analysis supports a controlled pilot, not a claim that add-ons themselves prevent churn.

### H3. Internet service type

**Hypothesis:** Fiber-optic customers churn more than DSL customers, potentially because of price or service competition.

- Fiber-optic customers(43.96% of total customers) have a reported churn rate of 41.89%, compared with 18.96% for DSL customers(34.38% of total customers).
- The gap remains in the contract-level comparisons. The dataset does not include service-quality or complaint information to explain the difference.

**Conclusion: The churn difference is supported; the proposed explanation is unconfirmed.**

**Implication:** investigate why fiber customers leave before choosing between pricing or service-quality actions.

### H4. Senior customers

**Hypotheses**

- **H4a — TechSupport:** Senior customers without TechSupport churn more than seniors with it.
- **H4b — Monthly charges:** Senior customers with higher monthly charges churn more than those with lower charges.

- Seniors cosist of 16.21% of total customers, and out of all the seniors 4.55% of them have no internet service.
- Among senior customers with internet service, the reported churn rates are 50.60% for customers without TechSupport and 19.62% for customers with it.
- In the 25+ month tenure group, the corresponding reported rate for customers without TechSupport is about 36%.
- Splitting senior customers above and below the median monthly charge shows nearly identical reported churn rates: 41.75% and 41.61%.

**Conclusion: H4a is supported as an association; H4b is not supported by the high/low comparison.**

**Implication:** TechSupport is associated with lower churn in the examined senior-customer groups, but this observational analysis cannot show that TechSupport caused the difference. A pilot could test whether targeted outreach improves retention.

### H5. Payment method

**Hypothesis:** Customers using manual payment methods churn more than those using automatic payment methods.

- 43.53% of customers used automatic payment method, while the rest(56.47%) used manual payment method.  
- Manual-payment customers have a reported churn rate of 34.67%, compared with 15.99% for automatic-payment customers.
- When payment types are examined separately, electronic check is the outlier at about 45.29%; mailed check is about 19.11%, closer to the automatic methods(around 15-17%).
- Electronic check remains an outlier in the month-to-month comparison. The dataset does not include cancellation reasons or payment failures to identify why.

**Conclusion: The broad manual-payment hypothesis is only partly supported; electronic check is the main outlier.**

**Implication:** investigate cancellation and billing records for electronic-check customers before selecting an intervention.

---
Full evidence, confound checks, and reasoning for each hypothesis are documented inline in [`telco_churn_analysis.sql`](./telco_churn_analysis.sql).

## Recommendations

1. Test early-tenure onboarding and month-to-month contract-conversion offers, tracking retention and discount costs.
2. Pilot TechSupport outreach for senior customers and compare results with a similar group that did not receive the offer.
3. Investigate fiber-customer cancellation reasons before committing to a pricing or service-quality response.
4. Test add-on offers with a control group before considering a wider rollout.
5. Check billing and cancellation records to understand electronic-check churn.

## Limitations

- **Single snapshot, no dates**, can't distinguish a worsening trend from a stable, ongoing pattern.
- **No service-quality, complaint, or payment-failure data**, several findings (H3, H5) show a real, confirmed pattern but an unconfirmed *cause*, because competing explanations can't be distinguished with the data available.
- **Association, not causation**, every recommendation involving a new intervention is framed as "test/investigate first," not "roll out," since this is observational data, not an experiment.

## Files

- [`telco_churn_analysis.sql`](./telco_churn_analysis.sql), full SQL analysis: data cleaning, all 7 hypotheses with inline reasoning, evidence, and conclusions.
- `README.md`, this file.

## SQL script sections

The SQL file is organized into database and table setup, data import, data checks and cleaning, overall churn analysis, five hypothesis sections, recommendations, and limitations.