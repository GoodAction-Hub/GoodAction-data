#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=yaml_utils.sh
source "$(dirname "$0")/yaml_utils.sh"

# Parse a Markdown table into YAML food entries.
# Expected table format (header row + separator row + data rows):
#   | 品名 / Dish | 价格 / Price |
#   | --- | --- |
#   | 招牌咖啡 | ¥35 |
append_yaml_food_table() {
  local file_path="$1"
  local table="$2"
  local indent="$3"
  local has_rows=0

  while IFS= read -r line; do
    [[ "$line" =~ ^\| ]] || continue
    [[ "$line" =~ ^\|[[:space:]]*-+[[:space:]]*\| ]] && continue

    local name price
    name=$(printf '%s' "$line" | awk -F'|' '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); print $2}')
    price=$(printf '%s' "$line" | awk -F'|' '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $3); print $3}')

    # Skip header row (name column contains non-digit non-Chinese characters typical of headers)
    [ -z "$name" ] && continue
    [[ "$name" =~ ^(品名|Dish|名称|Name) ]] && continue

    if [ "$has_rows" -eq 0 ]; then
      printf '%sfood:\n' "$indent" >> "$file_path"
    fi
    has_rows=1
    printf '%s  - name: "%s"\n' "$indent" "$(yaml_escape "$name")" >> "$file_path"
    printf '%s    price: "%s"\n' "$indent" "$(yaml_escape "$price")" >> "$file_path"
  done <<< "$table"
}

RESTAURANTS_FILE="${RESTAURANTS_FILE_PATH:-data/restaurants.yml}"

{
  printf -- '- id: "%s"\n' "$(yaml_escape "${RESTAURANT_ID:-}")"
  printf '  name: "%s"\n' "$(yaml_escape "${ISSUE_TITLE:-}")"
  printf '  description: "%s"\n' "$(yaml_escape "${RESTAURANT_DESCRIPTION:-}")"
} >> "$RESTAURANTS_FILE"

append_yaml_split_array "$RESTAURANTS_FILE" "  " "features" "${RESTAURANT_FEATURES:-}"

append_yaml_food_table "$RESTAURANTS_FILE" "${RESTAURANT_FOOD:-}" "  "

{
  printf '  avg_spend: "%s"\n' "$(yaml_escape "${RESTAURANT_AVG_SPEND:-}")"
} >> "$RESTAURANTS_FILE"

append_yaml_split_array "$RESTAURANTS_FILE" "  " "social_values" "${RESTAURANT_SOCIAL_VALUES:-}"

{
  printf '  address: "%s"\n' "$(yaml_escape "${RESTAURANT_ADDRESS:-}")"
  printf '  lat: "%s"\n' "$(yaml_escape "${RESTAURANT_LAT:-}")"
  printf '  lng: "%s"\n' "$(yaml_escape "${RESTAURANT_LNG:-}")"
  printf '  issue_link: "%s"\n' "$(yaml_escape "${ISSUE_LINK:-}")"
} >> "$RESTAURANTS_FILE"
