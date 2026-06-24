---
name: Metric Gap
about: Report a missing metric, wrong metric name, or broken metric reference in a dashboard or rule
labels: metric-gap, bug
---

## Affected Dashboard or Rule File

Which file is affected?

- Dashboard: `dashboards/`
- Recording rule: `prometheus/rules/`
- Alert rule: `prometheus/rules/`

## Client and Version

- Client: (e.g., `lighthouse v5.3.0`, `geth v1.14.0`)
- Deployment: (e.g., Kurtosis ethereum-package, standalone Docker)

## The Problem

Describe what is wrong. Examples:
- A panel shows "No data" despite the client running
- A metric name has changed in a newer client version
- A label is different from what the dashboard expects

## Expected Metric Name / Labels

What metric name and label set do you expect?

```promql
expected_metric_name{expected_label="value"}
```

## Actual Metric Name / Labels

What does your `/metrics` endpoint actually expose?

```promql
actual_metric_name{actual_label="value"}
```

## How to Reproduce

1. Run client: ...
2. Scrape `http://localhost:<port>/metrics`
3. Observe: ...

## Additional Context

Paste a sample of the actual `/metrics` output here if helpful.
