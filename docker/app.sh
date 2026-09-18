#!/bin/bash

# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Dmitry Paevsky

set -uo pipefail

CACHE_DIR="/tmp/docker_netns_cache"
CACHE_TTL=60
METRICS_DIR=/app/metrics
METRICS_FILE="$METRICS_DIR/metrics.prom"
SOCK=/var/run/docker.sock
API=http://localhost/v1.29

mkdir -p "$CACHE_DIR" "$METRICS_DIR"
CACHE_FILE="$CACHE_DIR/netns_map"
NOW=$(date +%s)

if [[ ! -f $CACHE_FILE || $(( NOW - $(stat -c %Y "$CACHE_FILE") )) -gt $CACHE_TTL ]]; then
  : > "$CACHE_FILE"
  for cid in $(curl -s --unix-socket "$SOCK" "$API/containers/json" | jq -r '.[].Id'); do
    curl -s --unix-socket "$SOCK" "$API/containers/$cid/json" \
    | jq -r '
        select(.NetworkSettings.SandboxKey != null and .NetworkSettings.SandboxKey != "")
        | [(.NetworkSettings.SandboxKey | split("/") | last),
           (.Name | ltrimstr("/"))]
        | @tsv' >> "$CACHE_FILE"
  done
fi

declare -A ns2name
while IFS=$'\t' read -r ns name; do
  [[ -n "$ns" && -n "$name" ]] && ns2name["$ns"]="$name"
done < "$CACHE_FILE"

TMP=$(mktemp "$METRICS_DIR/.metrics.XXXXXX")
{
  echo "# HELP docker_netns_tcp_state TCP sockets by state per container netns"
  echo "# TYPE docker_netns_tcp_state gauge"
} > "$TMP"

for ns_path in /var/run/docker/netns/*; do
  [[ -e "$ns_path" ]] || continue
  i=${ns_path##*/}
  cname=${ns2name[$i]:-}
  [[ -n "$cname" ]] || continue

  unset conn_states
  declare -A conn_states

  while read -r state; do
    [[ -n "$state" ]] || continue
    conn_states["$state"]=$(( ${conn_states["$state"]:-0} + 1 ))
  done < <(nsenter --net="$ns_path" ss -tan 2>/dev/null | awk 'NR>1 {print $1}')

  for state in "${!conn_states[@]}"; do
    printf 'docker_netns_tcp_state{container="%s",state="%s"} %d\n' \
           "$cname" "$state" "${conn_states[$state]}" >> "$TMP"
  done
done

mv "$TMP" "$METRICS_FILE"
