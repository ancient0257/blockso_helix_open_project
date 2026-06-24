#!/usr/bin/env bash
# check-prometheus.sh — validate Prometheus configs, rules, unit tests, and metric fixtures
set -euo pipefail

shopt -s nullglob

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

info()  { echo -e "${GREEN}[prometheus]${NC} $*"; }
warn()  { echo -e "${YELLOW}[prometheus]${NC} $*"; }
error() { echo -e "${RED}[prometheus]${NC} $*" >&2; }

checked=0

# Run promtool inside the official Prometheus Docker image
# Mounts the repo root as /workspace so relative paths in YAML files work
promtool() {
  docker run --rm \
    -v "$PWD:/workspace" \
    -w /workspace \
    --user "$(id -u):$(id -g)" \
    prom/prometheus:latest \
    promtool "$@"
}

# ── 1. Config files ──────────────────────────────────────────────────────────
configs=()
for pattern in \
    prometheus.yml prometheus.yaml \
    prometheus/prometheus.yml prometheus/prometheus.yaml; do
  [[ -f "$pattern" ]] && configs+=("$pattern")
done

if (( ${#configs[@]} > 0 )); then
  info "checking ${#configs[@]} config file(s)..."
  for cfg in "${configs[@]}"; do
    promtool check config "$cfg"
    info "  ✓ $cfg"
    (( checked++ )) || true
  done
else
  warn "no prometheus config files found"
fi

# ── 2. Rule files ────────────────────────────────────────────────────────────
rules=()
for pattern in \
    rules/*.yml rules/*.yaml \
    prometheus/rules/*.yml prometheus/rules/*.yaml; do
  [[ -f "$pattern" ]] && rules+=("$pattern")
done

if (( ${#rules[@]} > 0 )); then
  info "checking ${#rules[@]} rule file(s)..."
  promtool check rules "${rules[@]}"
  for r in "${rules[@]}"; do info "  ✓ $r"; done
  (( checked++ )) || true
else
  warn "no rule files found"
fi

# ── 3. Unit tests ────────────────────────────────────────────────────────────
tests=()
for pattern in \
    tests/*.test.yml tests/*.test.yaml \
    prometheus/tests/*.test.yml prometheus/tests/*.test.yaml; do
  [[ -f "$pattern" ]] && tests+=("$pattern")
done

if (( ${#tests[@]} > 0 )); then
  info "running ${#tests[@]} unit test file(s)..."
  promtool test rules "${tests[@]}"
  for t in "${tests[@]}"; do info "  ✓ $t"; done
  (( checked++ )) || true
else
  warn "no unit test files found"
fi

# ── 4. Metric fixtures ───────────────────────────────────────────────────────
fixture_errors=0
for fixture in fixtures/*.prom; do
  [[ -f "$fixture" ]] || continue
  if docker run --rm -i \
      --user "$(id -u):$(id -g)" \
      prom/prometheus:latest \
      promtool check metrics < "$fixture"; then
    info "  ✓ $fixture"
  else
    error "  ✗ $fixture"
    (( fixture_errors++ )) || true
  fi
  (( checked++ )) || true
done

if (( fixture_errors > 0 )); then
  error "$fixture_errors fixture(s) failed metric format check"
  exit 1
fi

# ── Summary ──────────────────────────────────────────────────────────────────
if (( checked == 0 )); then
  warn "nothing to check — add prometheus configs, rules, tests, or fixtures"
  exit 0
fi

info "all checks passed ✓"
