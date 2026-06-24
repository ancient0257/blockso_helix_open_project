# Execution Layer Client Metrics

This page catalogs the key Prometheus metrics exposed by each EL client that Helix dashboards use.

!!! note
    Metric names can change between client versions. The metrics listed here are based on stable releases as of 2024–2025. Always check your specific version's `/metrics` endpoint.

---

## Geth

**Metrics port:** `:6060/debug/metrics/prometheus`

| Metric | Type | Description |
|--------|------|-------------|
| `chain_head_block` | Gauge | Latest canonical head block number |
| `p2p_peers` | Gauge | Number of connected P2P peers |
| `txpool_pending` | Gauge | Pending transactions in the pool |
| `txpool_queued` | Gauge | Queued transactions in the pool |
| `eth_db_chaindata_cache_hit_total` | Counter | Chaindata cache hits |
| `eth_db_chaindata_cache_miss_total` | Counter | Chaindata cache misses |
| `eth_db_chaindata_disk_read_total` | Counter | Bytes read from disk |
| `eth_db_chaindata_disk_write_total` | Counter | Bytes written to disk |
| `rpc_duration_seconds` | Histogram | RPC method duration (labels: `method`) |
| `go_goroutines` | Gauge | Number of active goroutines |
| `go_gc_duration_seconds` | Summary | GC pause duration |
| `process_resident_memory_bytes` | Gauge | RSS memory |

**Key Engine API methods** (via `rpc_duration_seconds{method=...}`):
- `engine_forkchoiceUpdatedV3`
- `engine_newPayloadV3`
- `engine_getPayloadV3`

---

## Reth

**Metrics port:** `:9001/metrics`

| Metric | Type | Description |
|--------|------|-------------|
| `reth_blockchain_tree_canonical_chain_height` | Gauge | Latest canonical chain height |
| `reth_network_connected_peers` | Gauge | Connected P2P peers |
| `reth_network_pending_session_handshakes` | Gauge | Pending peer handshakes |
| `reth_db_freelist` | Gauge | MDBX freelist pages |
| `reth_engine_rpc_response_time_seconds` | Histogram | Engine API response time (labels: `method`) |
| `process_resident_memory_bytes` | Gauge | RSS memory |

---

## Erigon

**Metrics port:** `:6060/debug/metrics/prometheus`

| Metric | Type | Description |
|--------|------|-------------|
| `chain_head_block` | Gauge | Latest canonical head block |
| `stages_progress` | Gauge | Block progress per sync stage (labels: `stage`) |
| `p2p_peers` | Gauge | Connected P2P peers |
| `txpool_pending` | Gauge | Pending transactions |
| `txpool_queued` | Gauge | Queued transactions |
| `rpc_calls_total` | Counter | RPC calls by method |
| `process_resident_memory_bytes` | Gauge | RSS memory |

**Stage names** (via `stages_progress{stage=...}`):
`Headers`, `BorHeimdall`, `BlockHashes`, `Bodies`, `Senders`, `Execution`, `HashState`, `IntermediateHashes`, `AccountHistoryIndex`, `StorageHistoryIndex`, `LogIndex`, `CallTraces`, `TxLookup`, `Finish`

---

## Nethermind

**Metrics port:** `:9091/metrics`

| Metric | Type | Description |
|--------|------|-------------|
| `nethermind_blocks_sealed_total` | Counter | Total sealed blocks |
| `nethermind_peers_count` | Gauge | Connected P2P peers |
| `nethermind_jsonrpc_requests_total` | Counter | JSON-RPC requests by method |
| `dotnet_gc_heap_size_bytes` | Gauge | .NET GC heap size by generation |
| `dotnet_gc_collections_total` | Counter | GC collections by generation |
| `dotnet_thread_pool_queue_length` | Gauge | Thread pool work item queue depth |
| `process_resident_memory_bytes` | Gauge | RSS memory |

---

## Besu

**Metrics port:** `:9545/metrics`

| Metric | Type | Description |
|--------|------|-------------|
| `besu_peers_connected` | Gauge | Connected P2P peers |
| `besu_blockchain_chain_head_gas_used` | Gauge | Gas used in chain head block |
| `besu_rpc_server_request_time` | Histogram | RPC method request time |
| `jvm_memory_used_bytes` | Gauge | JVM memory used (labels: `area=heap\|nonheap`) |
| `jvm_memory_committed_bytes` | Gauge | JVM memory committed |
| `jvm_gc_collection_seconds` | Histogram | GC collection time (labels: `gc`) |
| `jvm_threads_current` | Gauge | JVM thread count |
| `process_resident_memory_bytes` | Gauge | RSS memory |
