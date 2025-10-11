#!/usr/bin/env -S uv run --script
# /// script
# dependencies = ["pydantic==2.11"]
# ///
#
#!MISE description="Generate json config from directory architecture"
#

import json
from pathlib import Path

from pydantic import BaseModel


class ConfigFile(BaseModel):
    name: str
    namespace: str


def main():
    base_dir = Path("./k8s1/apps")
    ns_config_file = Path("./k8s1/apps/grafana-k8s-monitoring/_namespaces.autogen.json")

    config_files = [f for f in base_dir.glob("**/_app_config.json")]
    configs = [ConfigFile.model_validate_json(f.read_text()) for f in config_files]
    # import pprint

    # pprint.pprint(configs)

    with open(ns_config_file, "wt", encoding="utf-8") as f:
        json.dump(
            {
                "namespaces": {c.namespace: None for c in configs},
            },
            f,
            indent=2,
        )


main()


# find ./k8s1/apps -mindepth 1 -maxdepth 1 -type d \
#   | xargs -I{} basename {}
