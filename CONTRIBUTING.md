# Contributing to Helix

Thank you for your interest in Helix! This guide covers everything you need to know to contribute dashboards, Prometheus rules, documentation, and more.

---

## Table of Contents

1. [Getting Started](#getting-started)
2. [Repository Structure](#repository-structure)
3. [Running Locally](#running-locally)
4. [Adding a Dashboard](#adding-a-dashboard)
5. [Adding Prometheus Rules](#adding-prometheus-rules)
6. [Writing Documentation](#writing-documentation)
7. [Running CI Checks](#running-ci-checks)
8. [PR Checklist](#pr-checklist)
9. [Code of Conduct](#code-of-conduct)

---

## Getting Started

1. **Fork** the repository and clone your fork:
   ```bash
   git clone https://github.com/<your-username>/Helix.git
   cd Helix
   git checkout -b my-feature
   ```

2. **Prerequisites**:
   - [Docker](https://docs.docker.com/get-docker/) (for running CI validation scripts locally)
   - [jq](https://jqlang.github.io/jq/) (for JSON validation)
   - [Python 3.8+](https://python.org) + [MkDocs](https://www.mkdocs.org/) (for docs only)

3. Make your changes, then run CI checks before pushing (see [Running CI Checks](#running-ci-checks)).

---

## Repository Structure

```
helix/
├── dashboards/          # Grafana dashboard JSON files (one per client or topic)
├── prometheus/
│   ├── prometheus.yml   # Main Prometheus scrape config
│   └── rules/           # Recording and alert rules (.yml)
│   └── tests/           # promtool unit tests for recording rules
├── provisioning/
│   ├── datasources/     # Grafana datasource YAML
│   └── dashboards/      # Grafana dashboard provisioner YAML
├── fixtures/            # Sample .prom metric exports (for CI)
├── docs/                # Markdown documentation (MkDocs)
├── website/             # Static landing page (HTML/CSS/JS)
├── scripts/             # Bash validation scripts used by CI
└── .github/             # GitHub Actions workflows, issue templates
```

---

## Running Locally

### Grafana + Prometheus (Docker Compose)

The quickest way to preview all dashboards is to run Grafana and Prometheus locally with Docker:

```bash
docker run -d --name helix-prometheus \
  -p 9090:9090 \
  -v "$PWD/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro" \
  -v "$PWD/prometheus/rules:/etc/prometheus/rules:ro" \
  prom/prometheus:latest

docker run -d --name helix-grafana \
  -p 3000:3000 \
  -e GF_SECURITY_ADMIN_USER=admin \
  -e GF_SECURITY_ADMIN_PASSWORD=admin \
  -v "$PWD/provisioning:/etc/grafana/provisioning:ro" \
  -v "$PWD/dashboards:/var/lib/grafana/dashboards:ro" \
  grafana/grafana-oss:latest
```

Open [http://localhost:3000](http://localhost:3000) and log in with `admin / admin`.

### MkDocs Docs

```bash
pip install mkdocs-material
mkdocs serve
```

Open [http://localhost:8000](http://localhost:8000).

---

## Adding a Dashboard

### Naming conventions

| Type | File name | Example |
|------|-----------|---------|
| Execution Layer client | `el-<client>.json` | `el-geth.json` |
| Consensus Layer client | `cl-<client>.json` | `cl-lighthouse.json` |
| Validator client | `vc-<topic>.json` | `vc-overview.json` |
| Cross-cutting topic | `<topic>.json` | `host-resources.json` |

### Required fields

Every dashboard JSON **must** have:

```json
{
  "uid":           "helix-<unique-slug>",
  "title":         "Helix — <Descriptive Title>",
  "tags":          ["helix", "<client-name>", "<layer>"],
  "schemaVersion": 39,
  "panels":        [...],
  "templating":    { "list": [...] }
}
```

### Required variables

Every dashboard **must** define these template variables (in this order):

1. **`datasource`** — type `datasource`, plugin `prometheus`
2. **`participant`** — type `query`, label values from `participant` label
3. **`client`** (EL/CL dashboards) — type `query`, label values for the specific client

### Panel guidelines

- Use **time series** panels for rate/gauge metrics over time
- Use **stat** panels for single current values (head slot, peer count, sync status)
- Use **table** panels for cross-client comparisons
- Use **heatmap** panels for histogram data (latency distributions)
- Add **thresholds** to stat panels (green/yellow/red)
- Include **panel descriptions** (`description` field) explaining what the metric means

### Validate your dashboard

```bash
jq empty dashboards/el-mynewclient.json
jq -e '.uid and .title and .panels' dashboards/el-mynewclient.json
```

---

## Adding Prometheus Rules

### Recording rules

Place recording rules in `prometheus/rules/` with the naming pattern:

- `el-recording.yml` — EL recording rules
- `cl-recording.yml` — CL recording rules

Use the following naming convention for recorded metrics:

```
helix:<layer>:<client>:<metric_description>
```

Example:
```yaml
- record: helix:el:geth:block_processing_rate5m
  expr: rate(chain_head_block[5m])
```

### Alert rules

Place alert rules in `prometheus/rules/` with the naming pattern `alerts-<topic>.yml`.

Every alert **must** have:
- `summary` annotation (one line)
- `description` annotation (explains root cause and impact)
- `severity` label (`critical`, `warning`, or `info`)
- `client` label (which client the alert targets, or `all`)

### Unit tests

Add unit tests for recording rules in `prometheus/tests/`. Use `promtool test rules` format:

```yaml
rule_files:
  - ../rules/el-recording.yml

tests:
  - interval: 1m
    input_series:
      - series: 'chain_head_block{job="ethereum-el-geth",participant="1"}'
        values: '0 1 2 3 4 5'
    promql_expr_test:
      - expr: helix:el:geth:block_processing_rate5m
        eval_time: 5m
        exp_samples:
          - labels: '{job="ethereum-el-geth",participant="1"}'
            value: 0.016666666666666666
```

### Validate your rules

```bash
./scripts/check-prometheus.sh
```

---

## Writing Documentation

Documentation lives in `docs/`. We use [MkDocs Material](https://squidfunk.github.io/mkdocs-material/).

- New metric catalogs go in `docs/metrics/`
- New contributor guides go in `docs/contributing/`
- Update `mkdocs.yml` when adding new pages

---

## Running CI Checks

Run both scripts before opening a PR:

```bash
# Validate Prometheus configs and rules
./scripts/check-prometheus.sh

# Validate Grafana dashboard JSON and provisioning
./scripts/check-grafana.sh
```

Both scripts require Docker to be running.

---

## PR Checklist

When opening a pull request, make sure:

- [ ] `./scripts/check-prometheus.sh` passes (if you changed prometheus files)
- [ ] `./scripts/check-grafana.sh` passes (if you changed dashboards)
- [ ] New dashboards follow the naming conventions above
- [ ] New dashboards have `uid`, `title`, `tags`, and `schemaVersion: 39`
- [ ] New dashboards include the required template variables
- [ ] Alert rules have `summary` and `description` annotations
- [ ] Documentation is updated if you added a new metric or dashboard
- [ ] The PR description references the related issue (e.g., `Closes #42`)

---

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](https://www.contributor-covenant.org/version/2/1/code_of_conduct/). Be respectful, constructive, and welcoming to all contributors regardless of experience level.

---

## Questions?

Open a [GitHub Discussion](https://github.com/BlocSoc-iitr/Helix/discussions) or file an [issue](https://github.com/BlocSoc-iitr/Helix/issues).
