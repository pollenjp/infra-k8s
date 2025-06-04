#!/usr/bin/env bash
#
# Requirements:
# - jsonnet (go-jsonnet)

set -eu -o pipefail

script_path=$(realpath "${BASH_SOURCE[0]}")
script_dir=$(dirname "$script_path")

find "$script_dir" -name "*.jsonnet" | while read -r jsonnet_file; do
  echo "Processing... $jsonnet_file"
  dirpath=$(dirname "$jsonnet_file")
  basename=$(basename "$jsonnet_file" .jsonnet)
  out_file="${dirpath}/.${basename}.gen.yaml"
  jsonnet "$jsonnet_file" | yq -p json -o yaml > "$out_file"
done
