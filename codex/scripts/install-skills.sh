#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
MANIFEST_PATH="${DOTFILES_DIR}/codex/skills/manifest.toml"
STATE_FILE="${HOME}/.codex/.managed-skills.txt"
AGENT="codex"
SCOPE_FLAG="--global"

mkdir -p "${HOME}/.codex" "${HOME}/.codex/skills"

if [[ ! -f "${MANIFEST_PATH}" ]]; then
  echo "No skills manifest found at ${MANIFEST_PATH}; skipping."
  exit 0
fi

if ! command -v npx >/dev/null 2>&1; then
  echo "npx is required for Codex skills installation. Install Node.js first." >&2
  exit 1
fi

parse_manifest() {
  python3 - "${MANIFEST_PATH}" <<'PY'
import sys
import tomllib
from pathlib import Path


def derive_repo_and_skill(skill_id: str) -> tuple[str, str]:
    raw = skill_id.strip("/")

    if "@" in raw:
        repo, skill = raw.rsplit("@", 1)
        repo_parts = repo.split("/")
        if len(repo_parts) != 2 or not all(repo_parts) or not skill:
            raise SystemExit(
                f"Invalid skill id '{skill_id}'. Expected owner/repo/skill or owner/repo@skill."
            )
        return repo, skill

    parts = raw.split("/")
    if len(parts) != 3 or not all(parts):
        raise SystemExit(
            f"Invalid skill id '{skill_id}'. Expected owner/repo/skill or owner/repo@skill."
        )

    owner, repo, skill = parts
    return f"{owner}/{repo}", skill


manifest_path = Path(sys.argv[1]).expanduser()
with manifest_path.open("rb") as fh:
    data = tomllib.load(fh)

sep = "\x1f"
seen_skill_names = set()
for skill in data.get("skills", []):
    skill_id = skill["id"]
    repo, skill_name = derive_repo_and_skill(skill_id)

    if skill_name in seen_skill_names:
        raise SystemExit(
            f"Duplicate skill name '{skill_name}' in manifest. "
            "Managed skills must have unique final skill names."
        )
    seen_skill_names.add(skill_name)

    enabled = "true" if skill.get("enabled", False) else "false"
    print(sep.join([repo, skill_name, enabled]))
PY
}

derive_repo_and_skill() {
  python3 - "$1" <<'PY'
import sys

skill_id = sys.argv[1].strip("/")

if "@" in skill_id:
    repo, skill = skill_id.rsplit("@", 1)
    repo_parts = repo.split("/")
    if len(repo_parts) != 2 or not all(repo_parts) or not skill:
        raise SystemExit(
            f"Invalid skill id '{skill_id}'. Expected owner/repo/skill or owner/repo@skill."
        )

    print(f"{repo}\x1f{skill}")
    raise SystemExit(0)

parts = skill_id.split("/")
if len(parts) != 3 or not all(parts):
    raise SystemExit(f"Invalid skill id '{skill_id}'. Expected owner/repo/skill or owner/repo@skill.")

owner, repo, skill = parts
print(f"{owner}/{repo}\x1f{skill}")
PY
}

canonicalize_skill_id() {
  local skill_id="$1"
  local derived
  local repo
  local skill_name

  derived="$(derive_repo_and_skill "${skill_id}")"
  IFS=$'\x1f' read -r repo skill_name <<< "${derived}"

  printf '%s@%s\n' "${repo}" "${skill_name}"
}

install_repo_skills() {
  local repo="$1"
  shift
  local skills=("$@")
  local skill_name
  local cmd=(npx --yes skills add "${repo}" --agent "${AGENT}" "${SCOPE_FLAG}" --yes)

  [[ ${#skills[@]} -eq 0 ]] && return 0

  for skill_name in "${skills[@]}"; do
    cmd+=(--skill "${skill_name}")
  done

  echo "Installing ${#skills[@]} skill(s) from ${repo}: ${skills[*]}"
  "${cmd[@]}" </dev/null
}

remove_skill() {
  local skill_name="$1"

  echo "Removing managed skill: ${skill_name}"
  npx --yes skills remove \
    "${skill_name}" \
    --agent "${AGENT}" \
    "${SCOPE_FLAG}" \
    --yes </dev/null
}

previous_state="$(mktemp)"
current_state="$(mktemp)"
manifest_rows="$(mktemp)"
enabled_rows="$(mktemp)"
enabled_rows_sorted="$(mktemp)"
trap 'rm -f "${previous_state}" "${current_state}" "${manifest_rows}" "${enabled_rows}" "${enabled_rows_sorted}"' EXIT

if [[ -f "${STATE_FILE}" ]]; then
  while IFS= read -r skill_id; do
    [[ -z "${skill_id}" ]] && continue
    canonicalize_skill_id "${skill_id}"
  done < "${STATE_FILE}" | sort -u > "${previous_state}"
else
  : > "${previous_state}"
fi

parse_manifest > "${manifest_rows}"

while IFS=$'\x1f' read -r repo skill_name enabled; do
  [[ -z "${repo}" ]] && continue
  [[ -z "${skill_name}" ]] && continue
  [[ "${enabled}" != "true" ]] && continue

  canonical_id="${repo}@${skill_name}"
  printf '%s\n' "${canonical_id}" >> "${current_state}"
  printf '%s\x1f%s\n' "${repo}" "${skill_name}" >> "${enabled_rows}"
done < "${manifest_rows}"

sort -u "${current_state}" -o "${current_state}"
sort -u "${enabled_rows}" > "${enabled_rows_sorted}"

current_repo=""
repo_skills=()
flush_repo_skills() {
  if [[ -n "${current_repo}" && ${#repo_skills[@]} -gt 0 ]]; then
    install_repo_skills "${current_repo}" "${repo_skills[@]}"
  fi
}

while IFS=$'\x1f' read -r repo skill_name; do
  [[ -z "${repo}" ]] && continue
  [[ -z "${skill_name}" ]] && continue

  if [[ -n "${current_repo}" && "${repo}" != "${current_repo}" ]]; then
    flush_repo_skills
    repo_skills=()
  fi

  current_repo="${repo}"
  repo_skills+=("${skill_name}")
done < "${enabled_rows_sorted}"

flush_repo_skills

while IFS= read -r previous_skill_id; do
  [[ -z "${previous_skill_id}" ]] && continue
  if ! rg -qx --fixed-strings "${previous_skill_id}" "${current_state}" >/dev/null 2>&1; then
    derived="$(derive_repo_and_skill "${previous_skill_id}")"
    IFS=$'\x1f' read -r _ skill_name <<< "${derived}"
    remove_skill "${skill_name}"
  fi
done < "${previous_state}"

mv "${current_state}" "${STATE_FILE}"
touch "${STATE_FILE}"

if [[ ! -s "${STATE_FILE}" ]]; then
  echo "No enabled skills in ${MANIFEST_PATH}; nothing installed."
fi
