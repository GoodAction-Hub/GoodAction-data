#!/usr/bin/env bash
# Shared YAML utility functions for data-save scripts.

yaml_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

# Append a YAML array from a comma-separated (or Chinese-comma-separated) string.
# Usage: append_yaml_split_array <file> <indent> <key> <value>
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
  done < <(printf '%s' "$value" | awk 'BEGIN{FS="[,，]"} {for (i=1; i<=NF; i++) {gsub(/^[[:space:]]+|[[:space:]]+$/, "", $i); if ($i != "") print $i}}')

  if [ "$has_items" -eq 0 ]; then
    printf '%s  []\n' "$indent" >> "$file_path"
  fi
}

# Parse a 2-column Markdown table and append YAML list entries.
# Usage: append_yaml_table <file> <indent> <list_key> <col1_key> <col2_key> <table> [header_pattern]
# header_pattern: ERE regex; rows where col1 matches are treated as headers and skipped.
# Expected table format (header row + separator row + data rows):
#   | 列1 / Col1 | 列2 / Col2 |
#   | --- | --- |
#   | value1 | value2 |
append_yaml_table() {
  local file_path="$1"
  local indent="$2"
  local list_key="$3"
  local col1_key="$4"
  local col2_key="$5"
  local table="$6"
  local header_pattern="${7:-}"
  local has_rows=0

  while IFS= read -r line; do
    # Only process lines that look like table rows
    [[ "$line" =~ ^\| ]] || continue
    # Skip separator rows (e.g. | --- | --- |)
    [[ "$line" =~ ^\|[[:space:]]*-+[[:space:]]*\| ]] && continue

    local col1 col2
    col1=$(printf '%s' "$line" | awk -F'|' '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); print $2}')
    col2=$(printf '%s' "$line" | awk -F'|' '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $3); print $3}')

    # Skip empty or header rows
    [ -z "$col1" ] && continue
    [ -n "$header_pattern" ] && [[ "$col1" =~ $header_pattern ]] && continue

    if [ "$has_rows" -eq 0 ]; then
      printf '%s%s:\n' "$indent" "$list_key" >> "$file_path"
      has_rows=1
    fi
    printf '%s  - %s: "%s"\n' "$indent" "$col1_key" "$(yaml_escape "$col1")" >> "$file_path"
    printf '%s    %s: "%s"\n' "$indent" "$col2_key" "$(yaml_escape "$col2")" >> "$file_path"
  done <<< "$table"
}
