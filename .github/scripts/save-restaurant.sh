#!/usr/bin/env bash
set -euo pipefail

yaml_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

append_yaml_split_array() {
  local file_path="$1"
  local indent="$2"
  local key="$3"
  local value="$4"
  local has_items=0

  printf '%s%s:\n' "$indent" "$key" >> "$file_path"

  while IFS= read -r item; do
    if [ -n "$item" ]; then
      has_items=1
      printf '%s  - "%s"\n' "$indent" "$(yaml_escape "$item")" >> "$file_path"
    fi
  done < <(printf '%s' "$value" | awk 'BEGIN{FS="[,，[:space:]]+"} {for (i=1; i<=NF; i++) if ($i != "") print $i}')

  if [ "$has_items" -eq 0 ]; then
    printf '%s  []\n' "$indent" >> "$file_path"
  fi
}

RESTAURANTS_FILE="${RESTAURANTS_FILE_PATH:-data/restaurants.yml}"

{
  printf -- '- id: "%s"\n' "$(yaml_escape "${RESTAURANT_ID:-}")"
  printf '  name: "%s"\n' "$(yaml_escape "${ISSUE_TITLE:-}")"
  printf '  description: "%s"\n' "$(yaml_escape "${RESTAURANT_DESCRIPTION:-}")"
} >> "$RESTAURANTS_FILE"

append_yaml_split_array "$RESTAURANTS_FILE" "  " "features" "${RESTAURANT_FEATURES:-}"

{
  printf '  food: "%s"\n' "$(yaml_escape "${RESTAURANT_FOOD:-}")"
  printf '  value: "%s"\n' "$(yaml_escape "${RESTAURANT_VALUE:-}")"
  printf '  address: "%s"\n' "$(yaml_escape "${RESTAURANT_ADDRESS:-}")"
  printf '  lat: "%s"\n' "$(yaml_escape "${RESTAURANT_LAT:-}")"
  printf '  lng: "%s"\n' "$(yaml_escape "${RESTAURANT_LNG:-}")"
  printf '  issue_link: "%s"\n' "$(yaml_escape "${ISSUE_LINK:-}")"
} >> "$RESTAURANTS_FILE"
