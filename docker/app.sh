#!/bin/bash

# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Dmitry Paevsky

CACHE_DIR="/tmp/docker_netns_cache"
CACHE_TTL=60  # секунд

METRICS_DIR=/app/metrics
METRICS_FILE="$METRICS_DIR/metrics.prom"

mkdir -p "$CACHE_DIR" "$METRICS_DIR"

CACHE_FILE="$CACHE_DIR/netns_map"
NOW=$(date +%s)

# Проверка TTL
if [[ ! -f $CACHE_FILE || $(( NOW - $(stat -c %Y "$CACHE_FILE") )) -gt $CACHE_TTL ]]; then
    echo "[INFO] Обновляю кэш docker netns → container name"
    > "$CACHE_FILE"
    # docker ps -q
    for cid in $(curl -s --unix-socket /var/run/docker.sock http://localhost/v1.29/containers/json | jq -r '.[].Id'); do
        # docker inspect --format '{{.NetworkSettings.SandboxKey}}' "$cid"
        ns=$(curl -s --unix-socket /var/run/docker.sock http://localhost/v1.29/containers/$cid/json | jq -r '.NetworkSettings.SandboxKey')
        # docker inspect --format '{{.Name}}' "$cid"
        name=$(curl -s --unix-socket /var/run/docker.sock http://localhost/v1.29/containers/$cid/json | jq -r '.Name' | sed 's|^/||')
        if [[ -n "$ns" && -n "$name" ]]; then
            echo "${ns##*/} ${name#/}" >> "$CACHE_FILE"
        fi
    done
else
    echo "[INFO] Использую кэш"
fi

# Формирование метрик
> "$METRICS_FILE"

for i in $(ls -1 /var/run/docker/netns); do
    cname=$(grep "^$i " "$CACHE_FILE" | awk '{print $2}')
    if [[ -n "$cname" ]]; then
        ns_path="/var/run/docker/netns/$i"
        declare -A conn_states
        while read -r state; do
            ((conn_states["$state"]++))
        done < <(nsenter --net="$ns_path" ss -tan | awk 'NR>1 {print $1}')

        for state in "${!conn_states[@]}"; do
            echo "docker_netns_tcp_state{container=\"${cname}\",state=\"${state}\"} ${conn_states[$state]}" >> "$METRICS_FILE"
        done
    fi
done

exit 0
