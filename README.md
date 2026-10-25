# texas-flood-losses
SQL analysis of FEMA flood insurance claims in Texas since 1978: where losses concentrate, how much comes from outside high-risk flood zones, and what made some claims far more costly than others. Built with DuckDB in Jupyter.

## Overall question: Where have Texas flood insurance losses come from since 1978, and what made some claims much more costly than others?

Sub-questions:
0. Data quality (setup, not a finding): nulls, negative payments, claims closed without payment, 1492 construction dates, 9999 elevation values, and how often the pre-FIRM and post-FIRM flags agree.

1) Where do losses concentrate? The Texas counties and zip codes with the most claims and the most net dollars paid, and how that changed by decade.

2) How much loss falls outside the high-risk zones? The share of Texas claims and dollars from outside the Special Flood Hazard Area, compared with FloodSmart’s one-in-three figure, by decade.

3) How concentrated are losses in a few big events? The share of dollars from the top 5 or 10 catastrophes (Harvey especially) versus smaller and unnamed floods.

4) Do building features reduce damage? Damage ratio by elevated status, post-FIRM construction and foundation type.

5) How often were policyholders underinsured? How often damage exceeded coverage, and how often coverage was below replacement cost, inside versus outside the high-risk zones.

Optional stretch: Do communities with better CRS classes show lower damage ratios?
