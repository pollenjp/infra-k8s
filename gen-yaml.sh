#!/usr/bin/env bash
#
# Requirements:
# - jsonnet (go-jsonnet)

set -eu -o pipefail

script_path=$(realpath "${BASH_SOURCE[0]}")
script_dir=$(dirname "$script_path")

# shellcheck disable=SC2016
find "$script_dir" -name "*.jsonnet" -print0 \
  | xargs -P0 -0 -I{} bash -c \
    ' set -eu -o pipefail
      jsonnet_file="$1"
      echo "Processing... $jsonnet_file"
      dirpath=$(dirname "$jsonnet_file")
      basename=$(basename "$jsonnet_file" .jsonnet)
      out_file="${dirpath}/.${basename}.gen.yaml"
      jsonnet "$jsonnet_file" | yq -p json -o yaml > "$out_file"
    ' _ {}
