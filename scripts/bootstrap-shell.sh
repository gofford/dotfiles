#!/usr/bin/env bash

set -euo pipefail

shell_path="$(brew --prefix)/bin/zsh"

if [[ ! -x "${shell_path}" ]]; then
  echo "Homebrew zsh not found at ${shell_path}; installing..."
  brew install zsh
fi

if ! grep -q "^${shell_path}$" /etc/shells 2>/dev/null; then
  echo "Adding ${shell_path} to /etc/shells..."
  sudo sh -c "echo ${shell_path} >> /etc/shells"
fi

current_shell="$(dscl . -read "/Users/${USER}" UserShell 2>/dev/null | awk '{print $2}')"
if [[ -z "${current_shell}" ]]; then
  current_shell="${SHELL:-}"
fi

if [[ "${current_shell}" != "${shell_path}" ]]; then
  echo "Changing default shell to ${shell_path}..."
  chsh -s "${shell_path}"
else
  echo "Shell already set to ${shell_path}"
fi
