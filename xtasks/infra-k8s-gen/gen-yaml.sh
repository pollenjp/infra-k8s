#!/usr/bin/env bash
#
#MISE description="Convert jsonnet to yaml (use the yaml information by Ansible)"
#MISE sources=["**/*.jsonnet", "**/*.json5", "**/*.json"]
#MISE outputs={ auto = true }
#
# Requirements:
# - jsonnet (go-jsonnet)

set -eu -o pipefail

# shellcheck disable=SC2016
find . -name "*.jsonnet" -print0 \
  | xargs -P0 -0 -I{} bash -c \
    ' set -eu -o pipefail
      jsonnet_file="$1"
      echo "Processing... $jsonnet_file"
      dirpath=$(dirname "$jsonnet_file")
      basename=$(basename "$jsonnet_file" .jsonnet)
      out_file="${dirpath}/.${basename}.gen.yaml"
      jsonnet "$jsonnet_file" | yq -p json -o yaml > "$out_file"
    ' _ {}
