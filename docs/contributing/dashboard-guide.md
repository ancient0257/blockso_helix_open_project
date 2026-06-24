# Dashboard Authoring Guide

This guide explains how to create a new Helix dashboard from scratch, following the project conventions.

## Before You Start

1. **Check if a dashboard already exists** — look in `dashboards/` first.
2. **Open an issue** — file a `new-dashboard` issue to discuss scope and metric selection before writing code.
3. **Read the metric reference** — check `docs/metrics/` to understand what metrics are available for your target client.

## File Naming

| Type | Naming Pattern | Example |
|------|---------------|---------|
| Execution Layer | `el-<client>.json` | `el-geth.json` |
| Consensus Layer | `cl-<client>.json` | `cl-lighthouse.json` |
| Validator Client | `vc-<topic>.json` | `vc-overview.json` |
| Cross-cutting | `<topic>.json` | `host-resources.json` |

## Required Fields

Every dashboard JSON **must** have all of these top-level fields:

```json
{
  "uid":           "helix-<unique-slug>",
  "title":         "Helix — <Descriptive Title>",
  "description":   "One-line description of what the dashboard covers.",
  "tags":          ["helix", "<client-name>", "<layer>"],
  "schemaVersion": 39,
  "version":       1,
  "refresh":       "30s",
  "time":          { "from": "now-1h", "to": "now" },
  "timezone":      "browser",
  "editable":      true,
  "graphTooltip":  1,
  "panels":        [...],
  "templating":    { "list": [...] }
}
```

## Required Template Variables

Every dashboard **must** define these variables in this order:

### 1. `datasource` — Prometheus datasource selector

```json
{
  "name": "datasource",
  "type": "datasource",
  "pluginId": "prometheus",
  "label": "Datasource",
  "hide": 0,
  "refresh": 1
}
```

### 2. `participant` — Kurtosis participant selector

```json
{
  "name": "participant",
  "type": "query",
  "label": "Participant",
  "datasource": { "type": "prometheus", "uid": "${datasource}" },
  "query": "label_values(<some_metric>{job=\"ethereum-<layer>-<client>\"}, participant)",
  "refresh": 2,
  "includeAll": true,
  "allValue": ".*",
  "multi": true,
  "sort": 1
}
```

Replace `<some_metric>` with a metric that is always present on the target client.

### 3. `client` (optional for cross-client dashboards)

If your dashboard spans multiple clients of the same type:

```json
{
  "name": "client",
  "type": "query",
  "label": "Client",
  "datasource": { "type": "prometheus", "uid": "${datasource}" },
  "query": "label_values(<some_metric>{client_type=\"el\"}, client)",
  "refresh": 2,
  "multi": true,
  "includeAll": true
}
```

## Panel Guidelines

### Panel types

| Data | Panel Type |
|------|-----------|
| Rate/gauge over time | `timeseries` |
| Single current value | `stat` |
| Cross-client comparison | `table` |
| Latency distributions | `heatmap` or `timeseries` with histogram_quantile |
| Disk fill, utilization | `gauge` |

### stat panels

Always add:
- `colorMode: "background"` for status panels (slot lag, peer count, sync status)
- Thresholds with green/yellow/red
- `reduceOptions.calcs: ["lastNotNull"]`
- `description` field explaining what the value means

Example:
```json
{
  "type": "stat",
  "title": "Slot Lag",
  "description": "Slots behind the current expected slot. 0 = healthy.",
  "options": {
    "colorMode": "background",
    "reduceOptions": { "calcs": ["lastNotNull"] }
  },
  "fieldConfig": {
    "defaults": {
      "unit": "none",
      "color": { "mode": "thresholds" },
      "thresholds": {
        "mode": "absolute",
        "steps": [
          { "color": "green", "value": null },
          { "color": "yellow", "value": 2 },
          { "color": "red", "value": 5 }
        ]
      }
    }
  }
}
```

### timeseries panels

Always add:
- `legend.displayMode: "table"` and `legend.placement: "bottom"` or `"right"`
- `tooltip.mode: "multi"` (shows all series at the cursor)
- `legendFormat` using `{{label_name}}` to distinguish participants
- A `description` field for the panel explaining what it shows

### Organizing panels with rows

Use `type: "row"` panels to group related panels:

```json
{
  "id": 10,
  "type": "row",
  "title": "Engine API Latency",
  "collapsed": false,
  "gridPos": { "h": 1, "w": 24, "x": 0, "y": 0 }
}
```

### Panel IDs

Panel IDs must be unique within a dashboard. Use sequential integers starting from 1.

## Validating Your Dashboard

Before submitting a PR:

```bash
# Validate JSON syntax
jq empty dashboards/el-mynewclient.json

# Validate required fields
jq -e '.uid and .title and .panels' dashboards/el-mynewclient.json

# Run the full CI check (requires Docker)
./scripts/check-grafana.sh
```

## Recommended Workflow

1. Build the dashboard interactively in a local Grafana instance
2. Export to JSON from Dashboard Settings → JSON Model
3. Clean up the exported JSON (remove unused fields, fix legendFormats)
4. Add to `dashboards/` and run validation
5. Open a PR referencing your issue
