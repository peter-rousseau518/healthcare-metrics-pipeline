# Findings

Results from the October 2024 Care Compare release and Q2 2024 PBJ daily staffing data. Metric definitions are in [ADR-024](decisions.md). State-level and facility-level detail is in the [live dashboard](https://nursing-home-staffing.streamlit.app/).

## Scope

- **14,505 nursing homes** included in the staffing analysis.
- **42 excluded** (0.3%) for partial reporting (fewer than 60 days) or implausible values.
- **17 facilities** in PBJ are absent from the October 2024 provider list, likely closures after June 2024, and are excluded.

## 1. Staffing and occupancy are nearly unrelated

| Measure | National value |
|---|---|
| Average occupancy rate | 78.4% |
| Average licensed nurse (RN + LPN) hours per resident day | 1.55 |
| Average total nurse hours per resident day | 3.84 |
| Correlation, occupancy vs. licensed-nurse HPRD | −0.081 |

The correlation is negligible. The slight negative lean means fuller facilities have marginally fewer licensed-nurse hours per resident, but how full a facility is says almost nothing about how well it's staffed. The dashboard shows the correlation for each state, where local patterns can be stronger.

The national total of 3.84 hours per resident day matches CMS's published national average, which supports the accuracy of the load and the hour groupings.

## 2. Agency nurse use is concentrated in a small number of facilities

- The median facility gets **0.8%** of its RN and LPN hours from contract (agency) staff.
- The highest-ranked facility, **The Plaza Rehab and Nursing Center (NY)**, used about **3,331 contract licensed-nurse hours per week**, roughly 83 full-time nurses' worth.

Because the distribution is so skewed, a ranking communicates this better than an average. This is the dashboard's answer to the overtime question; why overtime itself can't be measured is explained in ADR-024.

## 3. Staffing by state and facility type

Averages for every state and facility type are in the dashboard's *Staffing by state & type* tab, with a CSV download.

## 4. Short-stay vs. long-stay trends

Quarterly trends for short-stay and long-stay quality measures are in the dashboard's *Short- vs. long-stay trends* tab. These measure resident outcomes, not length of stay, which isn't in the source data.

## Caveats

- Hours are reported per facility, not per nurse, so overtime and headcount are unknown.
- PBJ covers a single quarter; Care Compare measures cover their own reporting periods, which differ by measure.
- Correlation does not imply causation.
