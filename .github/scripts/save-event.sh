#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=yaml_utils.sh
source "$(dirname "$0")/yaml_utils.sh"

# Parse a Markdown table into YAML timeline entries.
# Expected table format (header row + separator row + data rows):
#   | 关键日期 / Deadline | 说明 / Description |
#   | --- | --- |
#   | 2025-10-19T23:59:00 | 论文征集截止 |
append_yaml_timeline() {
  local file_path="$1"
  local table="$2"
  local has_rows=0

  while IFS= read -r line; do
    # Only process lines that look like table rows
    [[ "$line" =~ ^\| ]] || continue
    # Skip separator rows (e.g. | --- | --- |)
    [[ "$line" =~ ^\|[[:space:]]*-+[[:space:]]*\| ]] && continue

    local deadline comment
    deadline=$(printf '%s' "$line" | awk -F'|' '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); print $2}')
    comment=$(printf '%s' "$line" | awk -F'|' '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $3); print $3}')

    # Skip header rows (deadline column starts with a digit for valid ISO date entries)
    [[ "$deadline" =~ ^[0-9] ]] || continue

    if [ "$has_rows" -eq 0 ]; then
      printf '      timeline:\n' >> "$file_path"
    fi
    has_rows=1
    printf '        - deadline: "%s"\n' "$(yaml_escape "$deadline")" >> "$file_path"
    printf '          comment: "%s"\n' "$(yaml_escape "$comment")" >> "$file_path"
  done <<< "$table"
}

ACTIVITIES_FILE="${ACTIVITIES_FILE_PATH:-data/activities.yml}"

{
  printf -- '- title: "%s"\n' "$(yaml_escape "${ISSUE_TITLE:-}")"
  printf '  category: "%s"\n' "$(yaml_escape "${ACTIVITY_TYPE:-}")"
  printf '  description: "%s"\n' "$(yaml_escape "${ACTIVITY_DESCRIPTION:-}")"
} >> "$ACTIVITIES_FILE"

append_yaml_split_array "$ACTIVITIES_FILE" "  " "tags" "${ACTIVITY_TAGS:-}"

{
  printf '  events:\n'
  printf '    - id: "%s"\n' "$(yaml_escape "${ACTIVITY_ID:-}")"
  printf '      link: "%s"\n' "$(yaml_escape "${ACTIVITY_LINK:-}")"
  printf '      start_time: "%s"\n' "$(yaml_escape "${ACTIVITY_START_TIME:-}")"
  printf '      end_time: "%s"\n' "$(yaml_escape "${ACTIVITY_END_TIME:-}")"
} >> "$ACTIVITIES_FILE"

append_yaml_timeline "$ACTIVITIES_FILE" "${ACTIVITY_TIMELINE:-}"

{
  printf '      timezone: "%s"\n' "$(yaml_escape "${ACTIVITY_TIMEZONE:-}")"
  printf '      place: "%s"\n' "$(yaml_escape "${ACTIVITY_PLACE:-}")"
  printf '      issue_link: "%s"\n' "$(yaml_escape "${ISSUE_LINK:-}")"
} >> "$ACTIVITIES_FILE"
