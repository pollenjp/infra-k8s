local name = (import 'config.json5').name;
local namespace = (import 'config.json5').namespace;

[
  {
    apiVersion: 'sts.min.io/v1alpha1',
    kind: 'PolicyBinding',
    metadata: {
      name: target.name,
      namespace: namespace,
    },
    spec: {
      application: target.application,
      policies: [
        'readwrite',
      ],
    }
  }

  for target in [
    (
      local svc_info = (import '../grafana-loki/config.json5');
      {
        name: svc_info.service_account_name,
        application: (
          {
            namespace: svc_info.namespace,
            serviceaccount: svc_info.service_account_name,
          }
        )
      }
    ),
  ]
]
