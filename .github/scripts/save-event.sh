#!/usr/bin/env bash
set -euo pipefail

yaml_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

append_yaml_split_array() {
  local file_path="$1"
  local key="$2"
  local value="$3"
  local has_items=0

  printf '  %s:\n' "$key" >> "$file_path"

  while IFS= read -r item; do
    if [ -n "$item" ]; then
      has_items=1
      printf '    - "%s"\n' "$(yaml_escape "$item")" >> "$file_path"
    fi
  done < <(printf '%s' "$value" | awk 'BEGIN{FS="[,，[:space:]]+"} {for (i=1; i<=NF; i++) if ($i != "") print $i}')

  if [ "$has_items" -eq 0 ]; then
    printf '    []\n' >> "$file_path"
  fi
}

START_TIME="${EVENT_START_TIME:-}"
DATE_PART=$(echo "$START_TIME" | grep -oE '[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}' | head -n1 | tr '/' '-')

if [ -z "$DATE_PART" ]; then
  echo "Unable to parse start_time: $START_TIME"
  exit 1
fi

IFS='-' read -r YEAR MONTH DAY <<< "$DATE_PART"

SAFE_TITLE=$(echo "${ISSUE_TITLE:-}" | \
  sed 's#[\\/:*?"<>|]#-#g; s/[[:space:]]\+/-/g; s/--\+/-/g; s/^-//; s/-$//')

if [ -z "$SAFE_TITLE" ]; then
  SAFE_TITLE="issue-${ISSUE_NUMBER:-unknown}"
fi

FILE_PATH="data/$YEAR/$MONTH/$DAY/$SAFE_TITLE.md"
EVENTS_FILE="${EVENTS_FILE_PATH:-data/events.yml}"
mkdir -p "$(dirname "$FILE_PATH")"
{
  printf '# %s\n\n' "${ISSUE_TITLE:-}"
  printf '%s\n' "${ISSUE_BODY:-}"
} > "$FILE_PATH"

{
  printf -- '- issue_link: "%s"\n' "$(yaml_escape "${ISSUE_LINK:-}")"
  printf '  file_path: "%s"\n' "$(yaml_escape "$FILE_PATH")"
  printf '  title: "%s"\n' "$(yaml_escape "${ISSUE_TITLE:-}")"
  printf '  start_time: "%s"\n' "$(yaml_escape "${EVENT_START_TIME:-}")"
  printf '  end_time: "%s"\n' "$(yaml_escape "${EVENT_END_TIME:-}")"
  printf '  location: "%s"\n' "$(yaml_escape "${EVENT_LOCATION:-}")"
  printf '  money: "%s"\n' "$(yaml_escape "${EVENT_MONEY:-}")"
  printf '  whistleblower: "%s"\n' "$(yaml_escape "${EVENT_WHISTLEBLOWER:-}")"
} >> "$EVENTS_FILE"

append_yaml_split_array "$EVENTS_FILE" "hypocrite" "${EVENT_HYPOCRITE:-}"
append_yaml_split_array "$EVENTS_FILE" "tags" "${EVENT_TAGS:-}"
