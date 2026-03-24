#!/usr/bin/env bash

set -euo pipefail

mode=""
working_dir=""
input_file=""
cleanup_input=""
stdout_file=""
stderr_file=""
script_dir="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
prompt_dir="${script_dir}/prompts"

claude_bin=""
timeout_bin=""
timeout_duration="${CLAUDE_COUNTER_REVIEW_TIMEOUT:-600}"
claude_model="${CLAUDE_COUNTER_REVIEW_MODEL:-opus}"
claude_effort="${CLAUDE_COUNTER_REVIEW_EFFORT:-high}"
claude_max_turns="${CLAUDE_COUNTER_REVIEW_MAX_TURNS:-6}"
claude_permission_mode="${CLAUDE_COUNTER_REVIEW_PERMISSION_MODE:-bypassPermissions}"
claude_bare="${CLAUDE_COUNTER_REVIEW_BARE:-0}"
review_tools="${CLAUDE_COUNTER_REVIEW_REVIEW_TOOLS:-Read,Grep,Glob}"
plan_critique_tools="${CLAUDE_COUNTER_REVIEW_PLAN_CRITIQUE_TOOLS:-Read,Grep,Glob}"
plan_counter_tools="${CLAUDE_COUNTER_REVIEW_PLAN_COUNTER_TOOLS:-}"
debug="${CLAUDE_COUNTER_REVIEW_DEBUG:-0}"
system_prompt_file=""
system_prompt=""
mode_args=()
claude_help=""
supports_append_system_prompt_file="0"
supports_max_turns="0"

cleanup() {
  [[ -n "${cleanup_input}" && -f "${cleanup_input}" ]] && rm -f "${cleanup_input}"
  [[ -n "${stdout_file}" && -f "${stdout_file}" ]] && rm -f "${stdout_file}"
  [[ -n "${stderr_file}" && -f "${stderr_file}" ]] && rm -f "${stderr_file}"
}

trap cleanup EXIT

print_env_error() {
  local mode_value="${1:-${mode:-unknown}}"
  local error_message="$2"
  cat <<EOF
Status: ENVIRONMENT ERROR
Mode: ${mode_value}
Error:
${error_message}
EOF
}

die_env() {
  print_env_error "${1:-${mode:-unknown}}" "$2"
  exit "${3:-1}"
}

debug_log() {
  [[ "${debug}" == "1" ]] || return 0
  printf 'DEBUG: %s\n' "$*" >&2
}

require_flag_value() {
  local flag="$1"
  local value="${2-}"
  if [[ -z "${value}" || "${value}" == --* ]]; then
    die_env "${mode:-unknown}" "Missing value for ${flag}."
  fi
}

set_once() {
  local current_value="$1"
  local flag="$2"
  local value="$3"
  if [[ -n "${current_value}" ]]; then
    die_env "${mode:-unknown}" "Duplicate argument: ${flag}."
  fi
  printf '%s' "${value}"
}

append_tools_arg() {
  local tools="$1"
  if [[ -n "${tools}" ]]; then
    mode_args+=(--tools "${tools}")
  fi
  return 0
}

resolve_timeout_bin() {
  if command -v gtimeout >/dev/null 2>&1; then
    timeout_bin="$(command -v gtimeout)"
  elif command -v timeout >/dev/null 2>&1; then
    timeout_bin="$(command -v timeout)"
  else
    timeout_bin=""
  fi
}

detect_claude_capabilities() {
  if claude_help="$("${claude_bin}" --help 2>/dev/null)"; then
    [[ "${claude_help}" == *"--append-system-prompt-file"* ]] && supports_append_system_prompt_file="1"
    [[ "${claude_help}" == *"--max-turns"* ]] && supports_max_turns="1"
  else
    claude_help=""
  fi
  return 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      require_flag_value "$1" "${2-}"
      mode="$(set_once "${mode}" "$1" "$2")"
      shift 2
      ;;
    --working-dir)
      require_flag_value "$1" "${2-}"
      working_dir="$(set_once "${working_dir}" "$1" "$2")"
      shift 2
      ;;
    --input-file)
      require_flag_value "$1" "${2-}"
      input_file="$(set_once "${input_file}" "$1" "$2")"
      shift 2
      ;;
    *)
      die_env "${mode:-unknown}" "Unknown argument: $1." 2
      ;;
  esac
done

if [[ -z "${mode}" || -z "${working_dir}" ]]; then
  die_env "${mode:-unknown}" "Missing required arguments. Expected --mode and --working-dir."
fi

case "${mode}" in
  review)
    system_prompt_file="${prompt_dir}/review.txt"
    mode_args=(
      --permission-mode "${claude_permission_mode}"
    )
    append_tools_arg "${review_tools}"
    ;;
  plan-counter)
    system_prompt_file="${prompt_dir}/plan-counter.txt"
    mode_args=(
      --permission-mode "${claude_permission_mode}"
    )
    append_tools_arg "${plan_counter_tools}"
    ;;
  plan-critique)
    system_prompt_file="${prompt_dir}/plan-critique.txt"
    mode_args=(
      --permission-mode "${claude_permission_mode}"
    )
    append_tools_arg "${plan_critique_tools}"
    ;;
  *)
    die_env "${mode}" "Unsupported mode. Expected one of: review, plan-counter, plan-critique."
    ;;
esac

if [[ ! -d "${working_dir}" ]]; then
  die_env "${mode}" "Working directory does not exist: ${working_dir}"
fi

if [[ ! -r "${working_dir}" || ! -x "${working_dir}" ]]; then
  die_env "${mode}" "Working directory is not accessible: ${working_dir}"
fi

if [[ -z "${input_file}" ]]; then
  input_file="$(mktemp)"
  cat > "${input_file}"
  cleanup_input="${input_file}"
fi

if [[ ! -f "${input_file}" ]]; then
  die_env "${mode}" "Input file does not exist: ${input_file}"
fi

if [[ ! -r "${input_file}" ]]; then
  die_env "${mode}" "Input file is not readable: ${input_file}"
fi

if [[ ! -f "${system_prompt_file}" ]]; then
  die_env "${mode}" "System prompt file does not exist: ${system_prompt_file}"
fi

if [[ ! -r "${system_prompt_file}" ]]; then
  die_env "${mode}" "System prompt file is not readable: ${system_prompt_file}"
fi

if ! [[ "${claude_max_turns}" =~ ^[0-9]+$ ]] || (( claude_max_turns < 1 )); then
  die_env "${mode}" "CLAUDE_COUNTER_REVIEW_MAX_TURNS must be a positive integer. Got: ${claude_max_turns}"
fi

if [[ "${claude_bare}" != "0" && "${claude_bare}" != "1" ]]; then
  die_env "${mode}" "CLAUDE_COUNTER_REVIEW_BARE must be 0 or 1. Got: ${claude_bare}"
fi

if ! [[ "${timeout_duration}" =~ ^[0-9]+([smhd])?$ ]] || [[ "${timeout_duration}" == 0 || "${timeout_duration}" == 0s ]]; then
  die_env "${mode}" "CLAUDE_COUNTER_REVIEW_TIMEOUT must be a positive duration like 600, 600s, 10m, 1h, or 1d. Got: ${timeout_duration}"
fi

if ! claude_bin="$(command -v claude)"; then
  die_env "${mode}" "Claude CLI is not installed or not on PATH."
fi

if ! "${claude_bin}" --version >/dev/null 2>&1; then
  die_env "${mode}" "Claude CLI preflight failed."
fi

resolve_timeout_bin
detect_claude_capabilities
system_prompt="$(< "${system_prompt_file}")"

debug_log "mode=${mode}"
debug_log "working_dir=${working_dir}"
debug_log "input_file=${input_file}"
debug_log "input_bytes=$(wc -c < "${input_file}" | tr -d ' ')"
debug_log "claude_bin=${claude_bin}"
debug_log "timeout_bin=${timeout_bin:-none}"
debug_log "supports_append_system_prompt_file=${supports_append_system_prompt_file}"
debug_log "supports_max_turns=${supports_max_turns}"
debug_log "model=${claude_model} effort=${claude_effort} max_turns=${claude_max_turns} permission_mode=${claude_permission_mode} bare=${claude_bare}"

stdout_file="$(mktemp)"
stderr_file="$(mktemp)"

claude_cmd=(
  "${claude_bin}"
  -p
  --no-session-persistence
  --output-format text
  --model "${claude_model}"
  --effort "${claude_effort}"
  "${mode_args[@]}"
)

if [[ "${claude_bare}" == "1" ]]; then
  claude_cmd+=(--bare)
fi

if [[ "${supports_max_turns}" == "1" ]]; then
  claude_cmd+=(--max-turns "${claude_max_turns}")
fi

if [[ "${supports_append_system_prompt_file}" == "1" ]]; then
  claude_cmd+=(--append-system-prompt-file "${system_prompt_file}")
else
  claude_cmd+=(--append-system-prompt "${system_prompt}")
fi

run_claude() {
  if [[ -n "${timeout_bin}" ]]; then
    "${timeout_bin}" "${timeout_duration}" "${claude_cmd[@]}"
  else
    "${claude_cmd[@]}"
  fi
}

if (
  cd "${working_dir}" && \
  run_claude < "${input_file}"
) >"${stdout_file}" 2>"${stderr_file}"; then
  cat <<EOF
Status: OK
Mode: ${mode}

Output:
$(cat "${stdout_file}")
EOF
else
  exit_code=$?
  error_output="$(cat "${stderr_file}")"
  if [[ -z "${error_output}" ]]; then
    error_output="$(cat "${stdout_file}")"
  fi
  if [[ -n "${timeout_bin}" && ( "${exit_code}" -eq 124 || "${exit_code}" -eq 137 ) ]]; then
    error_output="Claude CLI timed out after ${timeout_duration}.

${error_output}"
  fi
  if [[ "${error_output}" == *"Not logged in"* || "${error_output}" == *"/login"* ]]; then
    error_output="Claude CLI reported an auth/login failure.

When this wrapper is launched from a sandboxed Codex subprocess, local Claude auth can be unavailable and produce a false 'Not logged in' error.
Retry this command from an escalated/unsandboxed path (sandbox_permissions=require_escalated) before treating this as a real login issue.

${error_output}"
  fi
  cat <<EOF
Status: ENVIRONMENT ERROR
Mode: ${mode}
Exit code: ${exit_code}

Error:
${error_output}
EOF
  exit "${exit_code}"
fi
