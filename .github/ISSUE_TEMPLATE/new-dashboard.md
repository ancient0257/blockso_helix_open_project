---
name: New Dashboard
about: Propose a new Grafana dashboard for a client or topic
labels: dashboard, enhancement
---

## Dashboard Description

What client or topic should this dashboard cover?

## Metric Sources

Which Prometheus scrape targets would this dashboard use?

- [ ] Native client metrics (specify client: )
- [ ] ethereum-metrics-exporter
- [ ] cAdvisor
- [ ] node_exporter

## Key Questions the Dashboard Should Answer

What debugging or operational questions should a user be able to answer by looking at this dashboard?

1.
2.
3.

## Key Metrics

List any specific Prometheus metric names you know are relevant:

```
metric_name{label="value"} ...
```

## Client Version

Which client version were the metrics captured from?

## Additional Context

Any existing dashboards (Grafana.com, client repos, etc.) that could serve as inspiration?
