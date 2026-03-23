#!/usr/bin/env bash

set -euo pipefail

config_file="${HOME}/.config/sheldon/plugins.toml"
lock_file="${HOME}/.config/sheldon/plugins.lock"

if [[ ! -f "${config_file}" ]]; then
  echo "No Sheldon config found at ${config_file}; skipping."
  exit 0
fi

if [[ ! -f "${lock_file}" || "${config_file}" -nt "${lock_file}" ]]; then
  echo "Updating Sheldon lock..."
  sheldon lock --update
else
  echo "Sheldon lock is up to date."
fi
