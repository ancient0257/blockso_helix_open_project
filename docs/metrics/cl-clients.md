# Consensus Layer Client Metrics

This page catalogs the key Prometheus metrics exposed by each CL client that Helix dashboards use.

!!! note
    Many CL clients share common metric names (e.g., `beacon_head_slot`) for interoperability. However, some metrics are client-specific. This page notes when metrics are shared vs. client-specific.

---

## Common Metrics (most CL clients)

The following metrics are available on most CL clients under the same name:

| Metric | Type | Description |
|--------|------|-------------|
| `beacon_head_slot` | Gauge | Current canonical head slot |
| `beacon_finalized_epoch` | Gauge | Latest finalized epoch |
| `beacon_current_justified_epoch` | Gauge | Current justified epoch |
| `process_resident_memory_bytes` | Gauge | RSS memory |
| `process_cpu_seconds_total` | Counter | CPU time |

---

## Lighthouse

**Beacon node port:** `:5054/metrics`  
**Validator client port:** `:5064/metrics`

| Metric | Type | Description |
|--------|------|-------------|
| `beacon_head_slot` | Gauge | Head slot |
| `beacon_finalized_epoch` | Gauge | Finalized epoch |
| `beacon_peer_connected_count` | Gauge | Connected libp2p peers |
| `beacon_attestation_processing_requests_total` | Counter | Attestations processed (labels: `result`) |
| `beacon_block_processing_seconds` | Histogram | Block import latency |
| `beacon_gossip_received_total` | Counter | Gossip messages received (labels: `topic`) |
| `beacon_libp2p_inbound_bytes_total` | Counter | libp2p inbound bytes |
| `beacon_libp2p_outbound_bytes_total` | Counter | libp2p outbound bytes |

---

## Prysm

**Beacon node port:** `:8080/metrics`  
**Validator client port:** `:8081/metrics`

| Metric | Type | Description |
|--------|------|-------------|
| `beacon_head_slot` | Gauge | Head slot |
| `beacon_current_justified_epoch` | Gauge | Justified epoch |
| `p2p_peer_count` | Gauge | Peer count (labels: `state=Connected\|Disconnected`) |
| `grpc_server_handling_seconds` | Histogram | gRPC method latency |
| `beacon_block_received_latency_seconds` | Histogram | Block receive-to-import latency |

---

## Teku

**Beacon node port:** `:8008/metrics`  
**Validator client port:** `:8009/metrics`

| Metric | Type | Description |
|--------|------|-------------|
| `beacon_head_slot` | Gauge | Head slot |
| `beacon_finalized_epoch` | Gauge | Finalized epoch |
| `libp2p_peers` | Gauge | Connected libp2p peers |
| `teku_rest_api_request_total` | Counter | REST API requests by method |
| `jvm_memory_used_bytes` | Gauge | JVM heap/nonheap used |
| `jvm_gc_collection_seconds` | Histogram | GC collection time |

---

## Nimbus

**Beacon node port:** `:8008/metrics`

| Metric | Type | Description |
|--------|------|-------------|
| `beacon_head_slot` | Gauge | Head slot |
| `beacon_finalized_epoch` | Gauge | Finalized epoch |
| `nbc_peers` | Gauge | Connected peers |
| `nbc_attestation_pool_attestations` | Gauge | Attestation pool size |
| `beacon_gossip_received_total` | Counter | Gossip messages received |

---

## Lodestar

**Beacon node port:** `:8008/metrics`

| Metric | Type | Description |
|--------|------|-------------|
| `beacon_head_slot` | Gauge | Head slot |
| `beacon_finalized_epoch` | Gauge | Finalized epoch |
| `libp2p_peers` | Gauge | Connected peers |
| `beacon_gossip_queue_length` | Gauge | Gossip queue depth by topic |
| `nodejs_eventloop_lag_seconds` | Histogram | Node.js event loop lag |
| `nodejs_heap_size_used_bytes` | Gauge | Node.js heap used |
| `nodejs_heap_size_total_bytes` | Gauge | Node.js heap total |

---

## Slot Lag Calculation

Helix calculates slot lag as:

```promql
floor(time() / 12) - beacon_head_slot
```

`12` is the slot time in seconds. Values above 2 trigger a warning alert. Values above 10 trigger a critical alert.

## Finality Lag Calculation

```promql
floor(time() / 384) - beacon_finalized_epoch
```

`384 = 32 slots × 12 seconds`. Values above 4 epochs sustained for 10 minutes indicate a finality stall.
