#!/usr/bin/env bash
set -uo pipefail

APP_DIR="${ALLOFME_APP_DIR:-/opt/allofme/app}"
ENV_FILE="${ALLOFME_ENV_FILE:-.env.production}"
DATA_DIR="${ALLOFME_DATA_DIR:-/opt/allofme/cloud-saves}"
BACKUP_DIR="${ALLOFME_BACKUP_DIR:-/opt/allofme/backups}"
BACKUP_LOG="${ALLOFME_BACKUP_LOG:-/var/log/allofme-backup.log}"
COMPOSE_SERVICE="${ALLOFME_COMPOSE_SERVICE:-api}"
CONTAINER_NAME="${ALLOFME_CONTAINER_NAME:-allofme-server}"
LOCAL_HEALTH_URL="${ALLOFME_LOCAL_HEALTH_URL:-http://127.0.0.1:3000/healthz}"
PUBLIC_HEALTH_URL="${ALLOFME_PUBLIC_HEALTH_URL:-https://api.allofmeapp.com/healthz}"
LOG_SINCE="${ALLOFME_LOG_SINCE:-24h}"
BACKUP_LOG_LINES="${ALLOFME_BACKUP_LOG_LINES:-80}"

section() {
  printf '\n== %s ==\n' "$1"
}

warn() {
  printf 'WARN: %s\n' "$*" >&2
}

run_optional() {
  "$@"
  local status=$?
  if [ "$status" -ne 0 ]; then
    warn "command failed with status $status: $*"
  fi
  return 0
}

check_url() {
  local label="$1"
  local url="$2"

  if ! command -v curl >/dev/null 2>&1; then
    warn "curl is not installed; skipping $label health check."
    return 0
  fi

  printf '%s: ' "$label"
  if curl --fail --show-error --silent --max-time 10 "$url"; then
    printf '\n'
  else
    local status=$?
    printf 'failed\n'
    warn "$label health check failed with status $status: $url"
  fi
}

run_in_app_dir() {
  if [ ! -d "$APP_DIR" ]; then
    warn "app directory does not exist: $APP_DIR"
    return 0
  fi

  (cd "$APP_DIR" && run_optional "$@")
}

latest_backup_path() {
  if [ ! -d "$BACKUP_DIR" ]; then
    return 1
  fi

  find "$BACKUP_DIR" \
    -maxdepth 1 \
    -type f \
    \( -name '*.tgz' -o -name '*.tar.gz' \) \
    -printf '%T@ %p\n' 2>/dev/null \
    | sort -nr \
    | sed -n '1s/^[^ ]* //p'
}

print_backup_age() {
  local backup_path
  backup_path="$(latest_backup_path)"
  if [ -z "$backup_path" ]; then
    warn "no backup archives found in $BACKUP_DIR"
    return 0
  fi

  local modified_at
  modified_at="$(stat -c '%Y' "$backup_path" 2>/dev/null)"
  if [ -z "$modified_at" ]; then
    warn "could not read backup mtime: $backup_path"
    printf 'Newest backup: %s\n' "$backup_path"
    return 0
  fi

  local now
  now="$(date +%s)"
  local age_seconds=$((now - modified_at))
  local age_hours=$((age_seconds / 3600))
  local age_days=$((age_seconds / 86400))

  printf 'Newest backup: %s\n' "$backup_path"
  printf 'Backup age: %s hours (%s days)\n' "$age_hours" "$age_days"
  printf 'Backup modified: '
  date -u -d "@$modified_at" '+%Y-%m-%dT%H:%M:%SZ'
}

section "All Of Me Ops Summary"
printf 'Host: %s\n' "$(hostname 2>/dev/null || printf 'unknown')"
printf 'Time: %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
printf 'App dir: %s\n' "$APP_DIR"
printf 'Data dir: %s\n' "$DATA_DIR"
printf 'Backup dir: %s\n' "$BACKUP_DIR"

section "Health"
check_url "local" "$LOCAL_HEALTH_URL"
check_url "public" "$PUBLIC_HEALTH_URL"

section "Disk"
run_optional df -hP / "$APP_DIR" "$DATA_DIR" "$BACKUP_DIR"

section "Data Size"
run_optional du -sh "$DATA_DIR" "$BACKUP_DIR"

section "Backup Age"
print_backup_age

section "Docker Compose"
run_in_app_dir docker compose --env-file "$ENV_FILE" ps

section "Admin Stats"
run_in_app_dir docker compose --env-file "$ENV_FILE" exec -T "$COMPOSE_SERVICE" node dist/admin-cli.js stats --json

section "Recent API Errors"
if command -v docker >/dev/null 2>&1; then
  docker logs --since "$LOG_SINCE" "$CONTAINER_NAME" 2>&1 \
    | grep -E '"level":(40|50)|"statusCode":5[0-9][0-9]|"errorId":|"err":|ERROR|Error' \
    | tail -50 \
    || true
else
  warn "docker is not installed; skipping recent API error scan."
fi

section "Backup Log"
if [ -f "$BACKUP_LOG" ]; then
  run_optional tail -n "$BACKUP_LOG_LINES" "$BACKUP_LOG"
else
  warn "backup log does not exist: $BACKUP_LOG"
fi
