#!/bin/bash
set -euo pipefail

for iface in en0 en1; do
  ip=$(ipconfig getifaddr "$iface" 2>/dev/null || true)
  if [ -n "$ip" ]; then
    echo "$ip"
    exit 0
  fi
done

echo "未取到局域网 IP" >&2
exit 1
