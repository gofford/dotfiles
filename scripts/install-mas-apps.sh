#!/usr/bin/env bash

set -euo pipefail

if ! mas account &>/dev/null; then
  echo "Not signed in to Mac App Store — skipping MAS installs."
  echo "Sign in to the App Store, then run: make step STEP=04-brew-mas"
  exit 0
fi

brew file install -f brew/Brewfile.mas
