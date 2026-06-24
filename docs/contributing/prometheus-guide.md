# Prometheus Guide

This guide covers how to add scrape jobs, recording rules, alert rules, and unit tests to Helix.

## Adding a Scrape Job

Scrape jobs are defined in `prometheus/prometheus.yml`. Each job should:

1. Use a descriptive job name: `ethereum-<layer>-<client>` (e.g., `ethereum-el-geth`)
2. Set the correct `metrics_path` for the client
3. Add `labels` for `client` and `client_type`
4. Use a `relabel_config` to extract the `participant` from the Kurtosis service name

### Template

```yaml
- job_name: "ethereum-el-mynewclient"
  metrics_path: /metrics         # or /debug/metrics/prometheus for Geth-style
  static_configs:
    - targets:
        - "el-1-mynewclient-lighthouse:PORT"
      labels:
        client: "mynewclient"
        client_type: "el"
  relabel_configs:
    - source_labels: [__address__]
      regex: "el-(\\d+)-.*"
      target_label: participant
      replacement: "$1"
```

### Kurtosis service name format

Kurtosis names EL services as: `el-<index>-<el-client>-<cl-client>`
Kurtosis names CL services as: `cl-<index>-<cl-client>-<el-client>`

The relabel regex `el-(\d+)-.*` captures the participant index.

## Adding Recording Rules

Recording rules live in `prometheus/rules/`. Use the naming convention:

```
helix:<layer>:<client>:<description>
```

Examples:
- `helix:el:geth:block_processing_rate5m`
- `helix:cl:lighthouse:slot_lag`
- `helix:el:reth:p2p_peers`

### Template

```yaml
groups:
  - name: helix.el.mynewclient
    interval: 30s
    rules:
      - record: helix:el:mynewclient:block_processing_rate5m
        expr: >
          rate(my_client_head_block{job="ethereum-el-mynewclient"}[5m])
```

### When to use recording rules

- When a query is reused in multiple dashboards
- When a query is expensive (e.g., `histogram_quantile` over many time series)
- When you want to pre-compute a derived metric (e.g., cache hit rate)

## Adding Alert Rules

Alert rules live in `prometheus/rules/alerts-<topic>.yml`.

### Required annotations

Every alert **must** have these annotations:

```yaml
annotations:
  summary: "One-line human-readable description"
  description: >
    Detailed explanation of: what caused this alert, what the impact is,
    and what to check to diagnose the issue.
```

### Required labels

```yaml
labels:
  severity: critical | warning | info
  client_type: el | cl | vc | infra
  client: <client-name>    # optional, for client-specific alerts
```

### Alert template

```yaml
- alert: ELMyNewClientPeerCountLow
  expr: >
    my_client_peers{job="ethereum-el-mynewclient"} < 3
  for: 5m
  labels:
    severity: warning
    client_type: el
    client: mynewclient
  annotations:
    summary: "mynewclient participant {{ $labels.participant }} has fewer than 3 peers"
    description: >
      The execution client mynewclient (participant {{ $labels.participant }})
      has {{ $value }} connected peers. Low peer count may affect sync quality.
```

### Alert severity guidelines

| Severity | Meaning | Response |
|----------|---------|----------|
| `critical` | Immediate impact (OOM, no peers, stalled sync) | Page immediately |
| `warning` | Degraded state (low peers, high latency) | Investigate within hours |
| `info` | Notable event (backfill complete, high txpool) | Log for awareness |

## Writing Unit Tests

Unit tests for recording rules live in `prometheus/tests/`. Use `promtool test rules` format.

### Template

```yaml
rule_files:
  - ../rules/el-recording.yml

evaluation_interval: 1m

tests:
  - interval: 1m
    input_series:
      - series: 'my_client_head_block{job="ethereum-el-mynewclient",participant="1"}'
        values: "0 5 10 15 20 25"

    promql_expr_test:
      - expr: helix:el:mynewclient:block_processing_rate5m
        eval_time: 5m
        exp_samples:
          - labels: '{job="ethereum-el-mynewclient",participant="1"}'
            value: 0.08333333333333333
```

### Running tests locally

```bash
# Using Docker (same as CI)
docker run --rm -v "$PWD:/workspace" -w /workspace \
  prom/prometheus:latest \
  promtool test rules prometheus/tests/el-recording.test.yml

# Or run all checks at once
./scripts/check-prometheus.sh
```

## Adding Metric Fixtures

Metric fixtures are sample `.prom` text files in `fixtures/` used by CI to validate metric format.

If you're adding support for a new client, add a sample fixture:

```bash
# If you have a running client, capture its metrics:
curl http://localhost:PORT/metrics > fixtures/mynewclient.prom

# Or create a minimal sample fixture by hand
cat > fixtures/mynewclient.prom << 'EOF'
# HELP my_metric_name Description of the metric.
# TYPE my_metric_name gauge
my_metric_name{job="ethereum-el-mynewclient",participant="1"} 12345
EOF
```

Fixtures are validated by `./scripts/check-prometheus.sh` using `promtool check metrics`.
