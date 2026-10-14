"""
Nursing Home Staffing & Occupancy Dashboard

Reads the dbt marts in Snowflake (healthcare.marts) using a read-only
service identity (DASHBOARD_READER role, STREAMLIT_SVC user, key-pair auth).
Metric definitions: docs/decisions.md, ADR-024.

Run locally:  streamlit run dashboard/app.py
Credentials:  ~/.streamlit/secrets.toml locally; the app's Secrets on
              Streamlit Community Cloud. Never committed to the repository.
"""
import numpy as np
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
import snowflake.connector
import streamlit as st
from cryptography.hazmat.primitives import serialization

st.set_page_config(page_title="Nursing Home Staffing & Occupancy", page_icon="🏥", layout="wide")

REPO_URL = "https://github.com/peter-rousseau518/healthcare-metrics-pipeline"
TYPE_COLUMNS = {
    "Ownership type": "ownership_group",
    "Provider type": "provider_type",
    "Facility setting": "facility_setting",
}
STAFFING_MEASURES = {
    "Licensed nurses (RN + LPN)": "licensed_nurse_hprd",
    "Registered nurses (RN)": "rn_hprd",
    "Licensed practical nurses (LPN)": "lpn_hprd",
    "All nursing staff (incl. aides)": "total_nurse_hprd",
}


# --- Data access ---------------------------------------------------------------

@st.cache_resource
def get_connection():
    cfg = st.secrets["snowflake"]
    key = serialization.load_pem_private_key(cfg["private_key"].encode(), password=None)
    key_der = key.private_bytes(
        encoding=serialization.Encoding.DER,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption(),
    )
    return snowflake.connector.connect(
        account=cfg["account"],
        user=cfg["user"],
        private_key=key_der,
        role=cfg["role"],
        warehouse=cfg["warehouse"],
        database=cfg["database"],
        schema=cfg["schema"],
        client_session_keep_alive=True,
    )


def _run(sql: str) -> pd.DataFrame:
    with get_connection().cursor() as cur:
        cur.execute(sql)
        df = cur.fetch_pandas_all()
    df.columns = [c.lower() for c in df.columns]
    return df


@st.cache_data(ttl=60 * 60 * 24, show_spinner="Loading data from Snowflake...")
def query(sql: str) -> pd.DataFrame:
    """Cached for 24 hours: the data changes monthly, so page views
    don't need to wake the warehouse (ADR-015)."""
    try:
        return _run(sql)
    except snowflake.connector.errors.Error:
        get_connection.clear()  # session may have expired; reconnect once
        return _run(sql)


facilities = query("""
    select ccn, provider_name, state, ownership_group, provider_type, facility_setting,
           is_chain_affiliated, calendar_quarter, certified_beds, avg_daily_census,
           occupancy_rate, rn_hprd, lpn_hprd, licensed_nurse_hprd, total_nurse_hprd,
           licensed_nurse_hours_per_week, licensed_nurse_fte_equivalent,
           contract_licensed_hours_per_week, contract_licensed_share,
           weekend_licensed_drop_pct, total_nursing_turnover_pct, rn_turnover_pct,
           contract_licensed_hours_rank, overall_rating
    from mart_facility_staffing
    where is_valid_for_analysis
""")
by_state_type = query("select * from mart_staffing_by_state_and_type")
daily = query("select * from mart_daily_staffing_trend")
quality = query("select * from mart_stay_type_quality_trend")

for frame in (facilities, by_state_type, daily, quality):
    for col in frame.columns:
        if frame[col].dtype == object and col.endswith(("_hprd", "_rate", "_share", "_pct", "_score")):
            frame[col] = pd.to_numeric(frame[col], errors="coerce")


# --- Sidebar filters -----------------------------------------------------------

st.sidebar.header("Filters")
quarter = st.sidebar.selectbox("Quarter", sorted(facilities["calendar_quarter"].unique(), reverse=True))
selected_states = st.sidebar.multiselect("States (leave blank for all)", sorted(facilities["state"].unique()))
type_dimension = st.sidebar.radio("Define facility type by", list(TYPE_COLUMNS))
type_col = TYPE_COLUMNS[type_dimension]

f = facilities[facilities["calendar_quarter"] == quarter]
if selected_states:
    f = f[f["state"].isin(selected_states)]
scope_label = ", ".join(selected_states) if selected_states else "All states"

st.sidebar.markdown("---")
st.sidebar.caption(
    f"Sources: CMS Payroll-Based Journal daily nurse staffing ({quarter}) and "
    f"CMS Nursing Home Care Compare (October 2024). "
    f"[Pipeline and definitions]({REPO_URL})"
)


# --- Header --------------------------------------------------------------------

st.title("Nursing Home Staffing & Occupancy")
st.caption(
    f"{len(f):,} nursing homes · {scope_label} · {quarter}. "
    "Staffing is measured in hours per resident day (HPRD): total nurse hours ÷ total resident-days."
)

tab1, tab2, tab3, tab4, tab5 = st.tabs([
    "Staffing vs. occupancy",
    "Agency nurse hours",
    "Staffing by state & type",
    "Short- vs. long-stay trends",
    "Daily trends",
])


def describe_correlation(r: float) -> str:
    if pd.isna(r):
        return "not enough data"
    size = abs(r)
    strength = "negligible" if size < 0.1 else "weak" if size < 0.3 else "moderate" if size < 0.5 else "strong"
    direction = "" if size < 0.1 else (" positive" if r > 0 else " negative")
    return f"{strength}{direction}"


# --- Tab 1: staffing vs occupancy ----------------------------------------------

with tab1:
    st.subheader("What is the relationship between nurse staffing and occupancy?")
    measure_label = st.radio("Staffing measure", list(STAFFING_MEASURES), horizontal=True, key="t1_measure")
    measure = STAFFING_MEASURES[measure_label]
    r = f["occupancy_rate"].corr(f[measure])

    c1, c2, c3, c4 = st.columns(4)
    c1.metric("Facilities", f"{len(f):,}")
    c2.metric("Average occupancy", f"{f['occupancy_rate'].mean():.1%}")
    c3.metric(f"Average {measure_label.split(' (')[0].lower()} HPRD", f"{f[measure].mean():.2f}")
    c4.metric("Correlation (r)", f"{r:.3f}", describe_correlation(r), delta_color="off")

    fig = px.scatter(
        f, x="occupancy_rate", y=measure, color=type_col, opacity=0.45,
        hover_name="provider_name", hover_data={"state": True, "certified_beds": True},
        labels={"occupancy_rate": "Occupancy rate", measure: f"{measure_label} HPRD", type_col: type_dimension},
        render_mode="webgl", height=520,
    )
    clean = f[["occupancy_rate", measure]].dropna()
    if len(clean) > 2:
        slope, intercept = np.polyfit(clean["occupancy_rate"], clean[measure], 1)
        xs = np.linspace(clean["occupancy_rate"].min(), clean["occupancy_rate"].max(), 50)
        fig.add_trace(go.Scatter(x=xs, y=slope * xs + intercept, mode="lines",
                                 name="Trend (all facilities)", line=dict(color="black", width=2)))
    fig.update_xaxes(tickformat=".0%")
    st.plotly_chart(fig, use_container_width=True)
    st.caption(
        f"r = {r:.3f} ({describe_correlation(r)}). Values near 0 mean occupancy tells you little about "
        "staffing; a negative value means fuller facilities have fewer nurse hours per resident."
    )

    st.markdown("**Correlation by state** (states with at least 20 facilities)")
    by_state = (
        f.groupby("state")
         .apply(lambda g: pd.Series({"facilities": len(g), "r": g["occupancy_rate"].corr(g[measure])}),
                include_groups=False)
         .reset_index()
    )
    by_state = by_state[by_state["facilities"] >= 20].sort_values("r")
    fig2 = px.bar(by_state, x="state", y="r", color="r", color_continuous_scale="RdBu", range_color=(-1, 1),
                  labels={"r": "Correlation (r)", "state": "State"}, height=380)
    fig2.update_layout(coloraxis_showscale=False)
    st.plotly_chart(fig2, use_container_width=True)


# --- Tab 2: agency nurse hours (overtime proxy) --------------------------------

with tab2:
    st.subheader("Which facilities rely most on extra nurse hours?")
    st.info(
        "**Why this isn't labeled overtime:** overtime means hours over 40 per nurse per week, which requires "
        "hours for each individual nurse. Public CMS data reports hours per facility per day, with no headcount. "
        "The closest public signal is **contract (agency) RN + LPN hours**: hours a facility's own staff did not "
        "cover. Weekend staffing drop and turnover are shown alongside as further signs of strain.",
        icon="ℹ️",
    )
    top_n = st.slider("Number of facilities to show", 10, 50, 20, step=5)

    c1, c2, c3 = st.columns(3)
    c1.metric("Median contract share of licensed hours", f"{f['contract_licensed_share'].median():.1%}")
    c2.metric("Facilities using no contract nurses", f"{(f['contract_licensed_hours_per_week'] == 0).mean():.0%}")
    c3.metric("Average weekend staffing drop", f"{f['weekend_licensed_drop_pct'].mean():.1%}")

    ranked = f.sort_values("contract_licensed_hours_per_week", ascending=False).head(top_n).copy()
    ranked["facility"] = ranked["provider_name"].str.title() + " (" + ranked["state"] + ")"
    fig = px.bar(
        ranked.iloc[::-1], x="contract_licensed_hours_per_week", y="facility", orientation="h",
        color="contract_licensed_share", color_continuous_scale="Oranges",
        labels={"contract_licensed_hours_per_week": "Contract RN + LPN hours per week", "facility": "",
                "contract_licensed_share": "Contract share"},
        height=max(400, 24 * len(ranked)),
    )
    fig.update_coloraxes(colorbar_tickformat=".0%")
    st.plotly_chart(fig, use_container_width=True)

    table = ranked[[
        "contract_licensed_hours_rank", "provider_name", "state", type_col, "certified_beds",
        "contract_licensed_hours_per_week", "contract_licensed_share", "licensed_nurse_hours_per_week",
        "licensed_nurse_fte_equivalent", "weekend_licensed_drop_pct", "total_nursing_turnover_pct",
    ]]
    st.dataframe(
        table, hide_index=True, use_container_width=True,
        column_config={
            "contract_licensed_hours_rank": st.column_config.NumberColumn("National rank", format="%d"),
            "provider_name": "Facility",
            "state": "State",
            type_col: type_dimension,
            "certified_beds": st.column_config.NumberColumn("Beds", format="%d"),
            "contract_licensed_hours_per_week": st.column_config.NumberColumn("Contract hrs/week", format="%.0f"),
            "contract_licensed_share": st.column_config.NumberColumn("Contract share", format="percent"),
            "licensed_nurse_hours_per_week": st.column_config.NumberColumn("All licensed hrs/week", format="%.0f"),
            "licensed_nurse_fte_equivalent": st.column_config.NumberColumn("FTE equivalents", format="%.1f",
                help="Weekly hours ÷ 40. Full-time nurses' worth of hours, not a headcount."),
            "weekend_licensed_drop_pct": st.column_config.NumberColumn("Weekend drop", format="percent"),
            "total_nursing_turnover_pct": st.column_config.NumberColumn("Nurse turnover %", format="%.1f"),
        },
    )


# --- Tab 3: staffing by state and type -----------------------------------------

with tab3:
    st.subheader("Average staffing levels by state and facility type")
    measure_label3 = st.radio("Staffing measure", list(STAFFING_MEASURES), horizontal=True, key="t3_measure")
    avg_col = "avg_" + STAFFING_MEASURES[measure_label3]

    s = by_state_type[(by_state_type["calendar_quarter"] == quarter)
                      & (by_state_type["facility_type_dimension"] == type_dimension)]

    national = s[s["state"] == "All states"].sort_values(avg_col, ascending=False)
    fig = px.bar(national, x="facility_type", y=avg_col, text_auto=".2f", hover_data=["facility_count"],
                 labels={"facility_type": type_dimension, avg_col: f"Average {measure_label3} HPRD"},
                 title=f"National average by {type_dimension.lower()}", height=380)
    st.plotly_chart(fig, use_container_width=True)

    states_only = s[s["state"] != "All states"]
    if selected_states:
        states_only = states_only[states_only["state"].isin(selected_states)]
    heat = states_only.pivot_table(index="state", columns="facility_type", values=avg_col)
    if not heat.empty:
        fig2 = px.imshow(heat, text_auto=".2f", aspect="auto", color_continuous_scale="Blues",
                         labels={"x": type_dimension, "y": "State", "color": "HPRD"},
                         title=f"Average {measure_label3} HPRD by state and {type_dimension.lower()}",
                         height=max(420, 22 * len(heat)))
        st.plotly_chart(fig2, use_container_width=True)
        st.caption("Blank cells: no valid facilities of that type in the state. "
                   "Averages count each facility once.")

    st.download_button(
        "Download this table (CSV)",
        s[["state", "facility_type", "facility_count", avg_col, "avg_occupancy_rate"]].to_csv(index=False),
        file_name=f"staffing_by_state_and_{type_col}_{quarter}.csv", mime="text/csv",
    )


# --- Tab 4: short- vs long-stay trends -----------------------------------------

with tab4:
    st.subheader("Short-stay vs. long-stay quality trends")
    st.info(
        "**About length of stay:** the CMS files do not include length of stay. This view trends quality "
        "measure scores for **short-stay** and **long-stay** residents across the four quarters of the "
        "measure period, the closest available data. Whether a higher score is better depends on the measure.",
        icon="ℹ️",
    )
    q = quality.copy()
    q["quarter"] = np.where(q["quarter_start"].notna(),
                            pd.to_datetime(q["quarter_start"]).dt.to_period("Q").astype(str),
                            "Q" + q["quarter_number"].astype(str))

    stay_types = sorted(q["resident_type"].dropna().unique())
    stay = st.radio("Resident type", stay_types, horizontal=True)
    qs = q[q["resident_type"] == stay]

    first = qs[qs["quarter_number"] == 1][["measure_code", "measure_description", "avg_score"]]
    last = qs[qs["quarter_number"] == 4][["measure_code", "avg_score"]]
    change = first.merge(last, on="measure_code", suffixes=("_q1", "_q4"))
    change["pct_change"] = (change["avg_score_q4"] - change["avg_score_q1"]) / change["avg_score_q1"].abs()
    change = change.sort_values("pct_change")
    fig = px.bar(change, x="pct_change", y="measure_description", orientation="h",
                 color="pct_change", color_continuous_scale="RdBu", range_color=(-0.5, 0.5),
                 labels={"pct_change": "Change, first to fourth quarter", "measure_description": ""},
                 title=f"{stay} measures: change across the measure period",
                 height=max(380, 40 * len(change)))
    fig.update_xaxes(tickformat=".0%")
    fig.update_layout(coloraxis_showscale=False)
    st.plotly_chart(fig, use_container_width=True)

    measure_names = qs.drop_duplicates("measure_code").set_index("measure_code")["measure_description"]
    if len(measure_names):
        pick = st.selectbox("Measure detail", measure_names.index, format_func=lambda c: measure_names[c])
        detail = qs[qs["measure_code"] == pick].sort_values("quarter_number")
        fig2 = px.line(detail, x="quarter", y=["avg_score", "median_score"], markers=True,
                       labels={"value": "Score", "quarter": "Quarter", "variable": ""},
                       title=measure_names[pick], height=380)
        st.plotly_chart(fig2, use_container_width=True)


# --- Tab 5: daily trends -------------------------------------------------------

with tab5:
    st.subheader("Daily occupancy and staffing across the quarter")
    trend_state = selected_states[0] if len(selected_states) == 1 else "All states"
    if len(selected_states) > 1:
        st.caption("Several states selected: showing the national trend. Select one state to see its trend.")
    d = daily[daily["state"] == trend_state].sort_values("work_date")
    weekend = d[d["is_weekend"]]

    for col, label, fmt in (("occupancy_rate", "Occupancy rate", ".1%"),
                            ("licensed_nurse_hprd", "Licensed nurse (RN + LPN) HPRD", ".2f")):
        fig = px.line(d, x="work_date", y=col, labels={"work_date": "", col: label},
                      title=f"{label}: {trend_state}", height=320)
        fig.add_trace(go.Scatter(x=weekend["work_date"], y=weekend[col], mode="markers",
                                 name="Weekend", marker=dict(color="crimson", size=6)))
        fig.update_yaxes(tickformat=fmt)
        st.plotly_chart(fig, use_container_width=True)
    st.caption("Red points are weekends. Licensed nurse HPRD typically dips on weekends.")


# --- Footer ----------------------------------------------------------------------

with st.expander("Definitions"):
    st.markdown(f"""
- **HPRD (hours per resident day):** total nurse hours ÷ total resident-days, the CMS method.
- **RN:** director of nursing + RN admin + direct-care RN. **LPN:** LPN admin + direct-care LPN.
  **Licensed nurses:** RN + LPN. **All nursing staff:** licensed nurses + CNAs, aides in training, and medication aides.
- **Occupancy rate:** average daily residents ÷ certified beds.
- **Contract hours:** hours worked by agency or contract staff rather than employees.
- **Facility type:** ownership (for profit / nonprofit / government), provider type (Medicare / Medicaid / both),
  or setting (hospital-based / freestanding).
- **Included facilities:** at least 60 reported days, occupancy 0-125%, total nurse HPRD 0.5-12
  (42 of about 14,500 excluded).

Full definitions and design decisions: [{REPO_URL}]({REPO_URL})
""")
