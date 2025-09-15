local argo_app_config = (import 'config.json5');

std.mergePatch(
  argo_app_config,
  {
    // Used in "../minio-tenant-1/policy-binding.jsonnet"
    "service_account_name": "mimir-sa",
    // Used in "../minio-tenant-1/manifests.jsonnet"
    "buckets": {
      // mimir target name : bucket name
      blocks_storage: "mimir-tsdb",
      ruler_storage: "mimir-ruler",
      alertmanager_storage: "mimir-ruler",
    },
  }
)
