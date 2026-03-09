#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=yaml_utils.sh
source "$(dirname "$0")/yaml_utils.sh"

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

# Parse timeline Markdown table: skip header rows (col1 doesn't start with a digit)
append_yaml_table "$ACTIVITIES_FILE" "      " "timeline" "deadline" "comment" \
  "${ACTIVITY_TIMELINE:-}" "^[^0-9]"

{
  printf '      timezone: "%s"\n' "$(yaml_escape "${ACTIVITY_TIMEZONE:-}")"
  printf '      place: "%s"\n' "$(yaml_escape "${ACTIVITY_PLACE:-}")"
  printf '      issue_link: "%s"\n' "$(yaml_escape "${ISSUE_LINK:-}")"
} >> "$ACTIVITIES_FILE"
