# Helix

**Devnet-aware Grafana dashboards for [ethpandaops/ethereum-package](https://github.com/ethpandaops/ethereum-package)**

Helix is an open-source collection of Grafana dashboards, Prometheus scrape configs, recording rules, and alert rules built specifically for Ethereum devnets running on [Kurtosis](https://github.com/kurtosis-tech/kurtosis). It combines three metric sources — **client-native metrics**, **ethereum-metrics-exporter**, and **cAdvisor/node_exporter** — into a curated set of operator-focused dashboards.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Kurtosis Enclave                         │
│                                                             │
│  EL Clients          CL Clients          Infrastructure     │
│  ─────────────       ──────────────       ───────────────   │
│  geth  :6060         lighthouse :5054     cadvisor   :8080  │
│  reth  :9001         prysm      :8080     node-exporter:9100│
│  erigon:6060         teku       :8008     eth-metrics :8080  │
│  nethermind:9091     nimbus     :8008                       │
│  besu  :9545         lodestar   :8008                       │
│                                                             │
│            ┌──────────────────────┐                         │
│            │     Prometheus       │◄── scrape_configs        │
│            │  (recording rules,   │    relabel_configs       │
│            │   alert rules)       │                         │
│            └──────────┬───────────┘                         │
│                       │                                     │
│            ┌──────────▼───────────┐                         │
│            │       Grafana        │◄── provisioning/         │
│            │  (Helix Dashboards)  │    dashboards/           │
│            └──────────────────────┘                         │
└─────────────────────────────────────────────────────────────┘
```

---

## Dashboard Index

| Dashboard | Description | Sources |
|-----------|-------------|---------|
| [Overview](dashboards/overview.json) | Single-pane devnet health | ethereum-metrics-exporter, cAdvisor |
| [Geth](dashboards/el-geth.json) | Geth sync, DB, RPC, P2P, GC | geth native metrics |
| [Reth](dashboards/el-reth.json) | Reth MDBX, pipeline stages, Engine API | reth native metrics |
| [Erigon](dashboards/el-erigon.json) | Erigon stage sync, MDBX, downloader | erigon native metrics |
| [Nethermind](dashboards/el-nethermind.json) | .NET runtime, trie sync, RPC | nethermind native metrics |
| [Besu](dashboards/el-besu.json) | JVM, RocksDB, Engine API, EVM | besu native metrics |
| [Lighthouse](dashboards/cl-lighthouse.json) | BN head, finality, gossip, P2P | lighthouse native metrics |
| [Prysm](dashboards/cl-prysm.json) | BN head, finality, gRPC latency | prysm native metrics |
| [Teku](dashboards/cl-teku.json) | JVM, BN head, REST API latency | teku native metrics |
| [Nimbus](dashboards/cl-nimbus.json) | Head, epoch processing, gossip | nimbus native metrics |
| [Lodestar](dashboards/cl-lodestar.json) | Node.js loop lag, BN head, DB | lodestar native metrics |
| [Validator Overview](dashboards/vc-overview.json) | Duty performance across all VCs | all VC native metrics |
| [Host Resources](dashboards/host-resources.json) | Container + host CPU/mem/disk/net | cAdvisor, node_exporter |
| [Cross-Client API](dashboards/ethereum-metrics-exporter.json) | Sync comparison across all ELs | ethereum-metrics-exporter |

---

## Quick Start

### Prerequisites
- [Kurtosis CLI](https://docs.kurtosis.com/install/)
- [Docker](https://docs.docker.com/get-docker/)

### 1. Launch a devnet with observability

```bash
kurtosis run github.com/ethpandaops/ethereum-package \
  --args-file https://raw.githubusercontent.com/ethpandaops/ethereum-package/main/network_params.yaml
```

### 2. Find Grafana

```bash
kurtosis enclave inspect <enclave-name>
# Look for the grafana service port mapping
```

### 3. Load Helix dashboards

```bash
# Clone this repo
git clone https://github.com/BlocSoc-iitr/Helix.git
cd Helix

# Mount provisioning + dashboards into Grafana
# (see docs/quickstart.md for detailed instructions)
```

Grafana credentials default to `admin / admin`.

---

## Repository Structure

```
helix/
├── dashboards/          # Grafana dashboard JSON files
├── prometheus/
│   ├── prometheus.yml   # Main Prometheus scrape config
│   └── rules/           # Recording and alert rules
├── provisioning/
│   ├── datasources/     # Grafana datasource YAML
│   └── dashboards/      # Grafana dashboard provisioner YAML
├── fixtures/            # Sample .prom files for CI metric validation
├── docs/                # Documentation (MkDocs)
├── website/             # Public landing page
├── scripts/             # Validation scripts (CI)
└── .github/             # CI workflows, issue templates
```

---

## Prometheus Labels

Helix dashboards use the following labels, which are injected via Prometheus `relabel_configs` from Kurtosis service names:

| Label | Description | Example |
|-------|-------------|---------|
| `client` | Client software name | `geth`, `lighthouse` |
| `client_type` | Layer type | `el`, `cl`, `vc` |
| `participant` | Participant index in the devnet | `1`, `2` |
| `job` | Prometheus scrape job | `ethereum-el-geth` |

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to add dashboards, prometheus rules, and documentation.  
Open issues and pull requests are welcome. Start with the [good first issue](https://github.com/BlocSoc-iitr/Helix/issues?q=is%3Aopen+label%3A%22good+first+issue%22) label.

---

## License

[Apache 2.0](LICENSE)
