local argo_app_config = (import '_app_config.json');

std.mergePatch(
  argo_app_config,
  {
    export_svc_name: argo_app_config.name + '-svc',
    export_svc_port: 80,
  },
)
