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

manifest_path = Path(sys.argv[1]).expanduser()
with manifest_path.open("rb") as fh:
    data = tomllib.load(fh)

sep = "\x1f"
seen_skill_names = set()
for skill in data.get("skills", []):
    skill_id = skill["id"].strip("/")
    parts = skill_id.split("/")
    if len(parts) != 3:
        raise SystemExit(f"Invalid skill id '{skill_id}'. Expected owner/repo/skill.")
    skill_name = parts[-1]
    if skill_name in seen_skill_names:
        raise SystemExit(
            f"Duplicate skill name '{skill_name}' in manifest. "
            "Managed skills must have unique final skill names."
        )
    seen_skill_names.add(skill_name)
    enabled = "true" if skill.get("enabled", False) else "false"
    print(sep.join([skill_id, enabled]))
PY
}

derive_repo_and_skill() {
  python3 - "$1" <<'PY'
import sys

skill_id = sys.argv[1].strip("/")
parts = skill_id.split("/")
if len(parts) != 3:
    raise SystemExit(f"Invalid skill id '{skill_id}'. Expected owner/repo/skill.")

owner, repo, skill = parts
print(f"{owner}/{repo}\x1f{skill}")
PY
}

install_skill() {
  local skill_id="$1"
  local derived
  local repo
  local skill_name

  derived="$(derive_repo_and_skill "${skill_id}")"
  IFS=$'\x1f' read -r repo skill_name <<< "${derived}"

  echo "Installing skill: ${skill_name} from ${repo}"
  npx --yes skills add "${repo}" \
    --skill "${skill_name}" \
    --agent "${AGENT}" \
    "${SCOPE_FLAG}" \
    --yes
}

remove_skill() {
  local skill_name="$1"

  echo "Removing managed skill: ${skill_name}"
  npx --yes skills remove \
    "${skill_name}" \
    --agent "${AGENT}" \
    "${SCOPE_FLAG}" \
    --yes
}

previous_state="$(mktemp)"
current_state="$(mktemp)"
manifest_rows="$(mktemp)"
trap 'rm -f "${previous_state}" "${current_state}" "${manifest_rows}"' EXIT

if [[ -f "${STATE_FILE}" ]]; then
  sort -u "${STATE_FILE}" > "${previous_state}"
else
  : > "${previous_state}"
fi

parse_manifest > "${manifest_rows}"

while IFS=$'\x1f' read -r skill_id enabled; do
  [[ -z "${skill_id}" ]] && continue
  [[ "${enabled}" != "true" ]] && continue

  printf '%s\n' "${skill_id}" >> "${current_state}"
  install_skill "${skill_id}"
done < "${manifest_rows}"

sort -u "${current_state}" -o "${current_state}"

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
