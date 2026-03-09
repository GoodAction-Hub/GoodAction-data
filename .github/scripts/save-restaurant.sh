#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=yaml_utils.sh
source "$(dirname "$0")/yaml_utils.sh"

RESTAURANTS_FILE="${RESTAURANTS_FILE_PATH:-data/restaurants.yml}"

{
  printf -- '- id: "%s"\n' "$(yaml_escape "${RESTAURANT_ID:-}")"
  printf '  name: "%s"\n' "$(yaml_escape "${ISSUE_TITLE:-}")"
  printf '  description: "%s"\n' "$(yaml_escape "${RESTAURANT_DESCRIPTION:-}")"
} >> "$RESTAURANTS_FILE"

append_yaml_split_array "$RESTAURANTS_FILE" "  " "features" "${RESTAURANT_FEATURES:-}"

# Parse food Markdown table: skip header rows by matching known header words in col1
append_yaml_table "$RESTAURANTS_FILE" "  " "food" "name" "price" \
  "${RESTAURANT_FOOD:-}" "^(品名|Dish|名称|Name)"

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
