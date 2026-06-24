#!/usr/bin/env bash
# check-grafana.sh — validate Grafana dashboard JSON files
# Runs without Docker if jq is available; validates:
#   1. Valid JSON syntax
#   2. Required top-level fields (uid, title, panels, schemaVersion, tags)
#   3. No duplicate UIDs across the dashboard library
#   4. Optionally, live Grafana health check via Docker
set -euo pipefail

shopt -s nullglob

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

info()  { echo -e "${GREEN}[grafana]${NC} $*"; }
warn()  { echo -e "${YELLOW}[grafana]${NC} $*"; }
error() { echo -e "${RED}[grafana]${NC} $*" >&2; }

# ── 1. Collect dashboards ────────────────────────────────────────────────────
dashboards=(dashboards/*.json)
if ((${#dashboards[@]} == 0)); then
  warn "no dashboards to check"
  exit 0
fi
info "found ${#dashboards[@]} dashboard(s)"

# ── 2. Per-file structural validation ───────────────────────────────────────
uids=()
errors=0

for f in "${dashboards[@]}"; do
  name=$(basename "$f")

  # 2a. Valid JSON
  if ! jq empty "$f" 2>/dev/null; then
    error "$name: invalid JSON"
    (( errors++ )) || true
    continue
  fi

  # 2b. Required fields
  missing=$(jq -r '
    [
      if .uid         then empty else "uid"         end,
      if .title       then empty else "title"       end,
      if .panels      then empty else "panels"      end,
      if .schemaVersion then empty else "schemaVersion" end,
      if .tags        then empty else "tags"        end
    ] | join(", ")
  ' "$f")
  if [[ -n "$missing" ]]; then
    error "$name: missing required field(s): $missing"
    (( errors++ )) || true
  fi

  # 2c. schemaVersion >= 36
  sv=$(jq -r '.schemaVersion // 0' "$f")
  if (( sv < 36 )); then
    error "$name: schemaVersion $sv is too old (need >= 36)"
    (( errors++ )) || true
  fi

  # 2d. Collect uid for uniqueness check
  uid=$(jq -r '.uid // ""' "$f")
  if [[ -z "$uid" ]]; then
    error "$name: uid is empty"
    (( errors++ )) || true
  else
    uids+=("$uid:$name")
  fi

  # 2e. All panels must have a non-zero id
  bad_panels=$(jq '[.panels[] | select(.id == null or .id == 0)] | length' "$f")
  if (( bad_panels > 0 )); then
    warn "$name: $bad_panels panel(s) have missing or zero id"
  fi
done

# ── 3. UID uniqueness across all dashboards ──────────────────────────────────
declare -A seen_uids
for entry in "${uids[@]}"; do
  uid="${entry%%:*}"
  file="${entry##*:}"
  if [[ -n "${seen_uids[$uid]+_}" ]]; then
    error "duplicate uid '$uid' in $file and ${seen_uids[$uid]}"
    (( errors++ )) || true
  else
    seen_uids["$uid"]="$file"
  fi
done

if (( errors > 0 )); then
  error "$errors error(s) found. Aborting."
  exit 1
fi
info "all dashboards passed structural checks ✓"

# ── 4. Live Grafana check (only if Docker is available) ──────────────────────
if ! command -v docker &>/dev/null; then
  warn "Docker not found — skipping live Grafana check"
  exit 0
fi
if [[ ! -d provisioning ]]; then
  warn "no provisioning/ directory — skipping live Grafana check"
  exit 0
fi

info "starting Grafana container for live check..."
docker run -d --rm \
  --name helix-grafana-ci \
  -e GF_SECURITY_ADMIN_USER=admin \
  -e GF_SECURITY_ADMIN_PASSWORD=admin \
  -e GF_LOG_LEVEL=warn \
  -p 3000:3000 \
  -v "$PWD/provisioning:/etc/grafana/provisioning:ro" \
  -v "$PWD/dashboards:/var/lib/grafana/dashboards:ro" \
  grafana/grafana-oss:latest > /dev/null

cleanup() { docker stop helix-grafana-ci > /dev/null 2>&1 || true; }
trap cleanup EXIT

for attempt in {1..30}; do
  if curl -fsS http://localhost:3000/api/health 2>/dev/null | jq -e '.database == "ok"' > /dev/null 2>&1; then
    loaded=$(curl -fsS -u admin:admin http://localhost:3000/api/search 2>/dev/null | jq length)
    info "Grafana healthy — $loaded dashboard(s) loaded via provisioning ✓"
    exit 0
  fi
  sleep 2
done

docker logs helix-grafana-ci
error "Grafana did not become healthy within 60s"
exit 1
