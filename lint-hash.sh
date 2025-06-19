#!/bin/bash

set -euo pipefail

hashed_sign=$(jsonnet -e '(import "jsonnetlib/hash.libsonnet") { data: "x" }.hashed_sign' | jq -r)
[[ -z "$hashed_sign" ]] && echo "Error: hashed_sign is empty" && exit 1

script_content=$(
  cat <<__EOF__
set -eu -o pipefail

jsonnet_file="\$1"
echo "Checking \$jsonnet_file..."

# Parse jsonnet and check ConfigMap names
jsonnet "\$jsonnet_file" | jq -r '
  if type == "array" then .[] else . end |
  select(
    .kind == "ConfigMap"
    or .kind == "OnePasswordItem"
  ) |
  .metadata.name |
  select(test("'"$hashed_sign"'$") | not)
' | while read -r invalid_name; do
  if [[ -n "\$invalid_name" ]]; then
    echo "Error: '\$invalid_name' in \$jsonnet_file does not match the hashed sign. Use 'hash.libsonnet' to generate the name."
    exit 1
  fi
done
__EOF__
)

# Find all jsonnet files
find . -name "*.jsonnet" -print0 | xargs -P0 -0 -I{} bash -c "$script_content" _ {}
