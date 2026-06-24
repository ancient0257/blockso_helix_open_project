# Quick Start

This guide walks you through launching an Ethereum devnet with Helix dashboards available in Grafana within 5 minutes.

## Prerequisites

- [Kurtosis CLI](https://docs.kurtosis.com/install/) — `brew install kurtosis-tech/tap/kurtosis-cli`
- [Docker Desktop](https://docs.docker.com/get-docker/) — must be running
- [Git](https://git-scm.com/)

## Step 1 — Clone Helix

```bash
git clone https://github.com/BlocSoc-iitr/Helix.git
cd Helix
```

## Step 2 — Launch a devnet with ethereum-package

The quickest way is to use the pre-built ethereum-package with observability enabled:

```bash
kurtosis run github.com/ethpandaops/ethereum-package \
  --args-file https://raw.githubusercontent.com/ethpandaops/ethereum-package/main/network_params.yaml \
  --enclave my-devnet
```

This will spin up:
- Two Ethereum participants (Geth + Lighthouse by default)
- A Prometheus instance
- A Grafana instance

## Step 3 — Find your Grafana port

```bash
kurtosis enclave inspect my-devnet | grep grafana
```

You'll see output like:
```
grafana  RUNNING  3000/tcp -> 0.0.0.0:32768
```

Open `http://localhost:32768` in your browser and log in with `admin / admin`.

## Step 4 — Load Helix dashboards

### Option A: Mount Helix into the running Grafana container (Docker)

```bash
# Find the Grafana container name
docker ps | grep grafana

# Copy provisioning config and dashboards
docker cp provisioning/ <grafana-container>:/etc/grafana/provisioning/
docker cp dashboards/ <grafana-container>:/var/lib/grafana/dashboards/

# Restart Grafana to pick up new provisioning
docker restart <grafana-container>
```

### Option B: Run a standalone Grafana with Helix pre-loaded

If you want a fresh Grafana with all Helix dashboards and the ethereum-package Prometheus as datasource:

```bash
# Replace <prometheus-port> with the port from kurtosis enclave inspect
PROMETHEUS_URL=http://host.docker.internal:<prometheus-port> \
docker run -d \
  --name helix-grafana \
  -p 3001:3000 \
  -e GF_SECURITY_ADMIN_USER=admin \
  -e GF_SECURITY_ADMIN_PASSWORD=admin \
  -e PROMETHEUS_URL="$PROMETHEUS_URL" \
  -v "$PWD/provisioning:/etc/grafana/provisioning:ro" \
  -v "$PWD/dashboards:/var/lib/grafana/dashboards:ro" \
  grafana/grafana-oss:latest
```

Open `http://localhost:3001` and log in with `admin / admin`.

All Helix dashboards will be available under the **Helix** folder.

## Step 5 — Explore

Start with the **Helix — Devnet Overview** dashboard. It answers:

- ✅ Is any EL client stalled?
- ✅ Is any CL client behind on head slot?
- ✅ Has finality stalled?
- ✅ Are any clients running low on peers?
- ✅ Is any container using excessive CPU or memory?

Then drill down to per-client dashboards (e.g., **Helix — Geth**) for deeper investigation.

## Cleaning up

```bash
kurtosis enclave stop my-devnet
kurtosis enclave rm my-devnet
docker stop helix-grafana && docker rm helix-grafana
```

## Troubleshooting

**No data in dashboards?**
- Check the `participant` variable at the top of the dashboard. Make sure at least one participant is selected.
- Check that Prometheus can scrape your Ethereum clients by opening `http://<prometheus-host>:<port>/targets`.

**Grafana can't reach Prometheus?**
- Make sure you're using `host.docker.internal` if Prometheus is on the host or in a different Docker network.
- Check the datasource configuration at `Connections > Data sources > Prometheus`.
