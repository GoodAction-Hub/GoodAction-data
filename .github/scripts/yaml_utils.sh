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
