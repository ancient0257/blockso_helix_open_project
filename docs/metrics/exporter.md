# ethereum-metrics-exporter Metrics

The [ethereum-metrics-exporter](https://github.com/ethpandaops/ethereum-metrics-exporter) provides a client-agnostic view of Ethereum node status by polling the standard JSON-RPC and Beacon Node APIs.

**Metrics port:** `:8080/metrics` (by default)

## Execution Layer Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `ethereum_sync_status` | Gauge | Sync status: 0 = synced, 1 = syncing |
| `ethereum_execution_layer_head_block_number` | Gauge | Canonical head block number |
| `ethereum_execution_layer_safe_block_number` | Gauge | Safe block number |
| `ethereum_execution_layer_finalized_block_number` | Gauge | Finalized block number |
| `ethereum_execution_layer_peer_count` | Gauge | Connected peer count |
| `ethereum_execution_layer_gas_limit` | Gauge | Current gas limit |
| `ethereum_execution_layer_gas_used` | Gauge | Gas used in the head block |

## Consensus Layer Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `ethereum_consensus_layer_head_slot` | Gauge | Current head slot |
| `ethereum_consensus_layer_finalized_epoch` | Gauge | Finalized epoch |
| `ethereum_consensus_layer_peer_count` | Gauge | Connected peer count |
| `ethereum_consensus_layer_sync_distance` | Gauge | Slots behind head (sync distance) |

## When to use ethereum-metrics-exporter vs. native metrics

| Question | Use exporter? | Use native? |
|----------|--------------|-------------|
| Is the EL synced? | ✅ Yes | |
| What is the current head block? | ✅ Yes | |
| How fast is the EL processing blocks? | | ✅ Yes |
| What is the Engine API latency? | | ✅ Yes |
| Is the database cache hot? | | ✅ Yes |
| What is the head slot? | ✅ Yes | ✅ Yes (preferred) |
| Are there validator duty misses? | | ✅ Yes (VC metrics) |

The exporter is best used as a **common baseline** to compare across clients when native metrics differ or are unavailable. For deep debugging, always prefer native client metrics.
