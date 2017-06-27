#! /bin/bash

headers() {
  local headers_string=$(tr --squeeze " " <<< "$1")
  [ ! -z "$FLAGS_jq" ] || string.join "\t" <<< "$headers_string"
}
output:headers() {
  local headers_string=$(tr --squeeze " " <<< "$1")
  [ ! -z "$jq" ] || string.join "\t" <<< "$headers_string"
}

headers.tags() {
  local tag_names="${1:-}"
  if [ ! -z "$tag_names" ]; then
    local headers=""

    for tag_name in $tag_names; do
      headers="$headers tag:$tag_name"
    done

    headers=$(string.strip "$headers")
    echo_if_not_blank "$headers" "$headers"
  fi
}
headers.tag() { headers.tags "$@"; }

output.tags() {
  local tag_names="${1:-}"
  local jq_filters="empty"
  if [ ! -z "$tag_names" ]; then
    for tag_name in $tag_names; do
      jq_filters="$jq_filters, (.Tags | tag_value(\"$tag_name\"))"
    done
  fi

  echo_if_not_blank "$jq_filters" "$jq_filters"
}
output.tag() { output.tags "$@"; }

echo_if_not_blank() {
  [ -z "$1" ] || echo "$2"
}
