#!/usr/bin/env bash

set -euo pipefail

failures=0

pass() { echo "PASS: $*"; }
warn() { echo "WARN: $*"; }
fail() { echo "FAIL: $*"; failures=$((failures + 1)); }

if command -v brew >/dev/null 2>&1; then
  pass "Homebrew is installed"
else
  fail "Homebrew is missing"
fi

if command -v brew >/dev/null 2>&1 && brew file --version >/dev/null 2>&1; then
  pass "brew-file is available"
else
  fail "brew-file is missing (run bootstrap)"
fi

if command -v sheldon >/dev/null 2>&1; then
  pass "sheldon is installed"
else
  fail "sheldon is missing"
fi

if command -v npx >/dev/null 2>&1; then
  pass "npx is installed"
else
  fail "npx is missing"
fi

if command -v mas >/dev/null 2>&1; then
  if mas account >/dev/null 2>&1; then
    pass "mas is installed and signed in"
  else
    warn "mas is installed but not signed in (MAS installs will be skipped)"
  fi
else
  warn "mas is not installed (MAS installs unavailable)"
fi

if command -v dockutil >/dev/null 2>&1; then
  pass "dockutil is installed"
else
  warn "dockutil is missing (make dock will be skipped)"
fi

if command -v brew >/dev/null 2>&1; then
  shell_path="$(brew --prefix)/bin/zsh"
  if [[ -x "${shell_path}" ]]; then
    if [[ "${SHELL:-}" == "${shell_path}" ]]; then
      pass "login shell is Homebrew zsh (${shell_path})"
    else
      warn "login shell is ${SHELL:-unknown}; expected ${shell_path}"
    fi
  else
    warn "Homebrew zsh not found at ${shell_path}"
  fi
fi

for dir in "${HOME}/.config/zsh" "${HOME}/.codex" "${HOME}/.claude"; do
  if [[ -d "${dir}" ]]; then
    pass "directory exists: ${dir}"
  else
    warn "directory missing: ${dir}"
  fi
done

for file in "${HOME}/.zshenv" "${HOME}/.gitconfig" "${HOME}/.ssh/config"; do
  if [[ -e "${file}" ]]; then
    pass "file exists: ${file}"
  else
    warn "file missing: ${file}"
  fi
done

if [[ "${failures}" -gt 0 ]]; then
  echo "doctor: ${failures} blocking issue(s) found."
  exit 1
fi

echo "doctor: no blocking issues found."
