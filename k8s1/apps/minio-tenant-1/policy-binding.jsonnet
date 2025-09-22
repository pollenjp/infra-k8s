local name = (import '_app_config.json').name;
local namespace = (import '_app_config.json').namespace;

[
  {
    apiVersion: 'sts.min.io/v1alpha1',
    kind: 'PolicyBinding',
    metadata: {
      name: target_and_policy.target.name,
      namespace: namespace,
    },
    spec: {
      application: target_and_policy.target.application,
      policies: [
        target_and_policy.policy,
      ],
    }
  }

  for target_and_policy in [
    {
      target: (
        local svc_info = (import '../grafana-mimir/_config.jsonnet');
        {
          name: svc_info.service_account_name + '-rw-binding',
          application: (
            {
              namespace: svc_info.namespace,
              serviceaccount: svc_info.service_account_name,
            }
          )
        }
      ),
      policy: 'readwrite', // FIXME: permissions are excessive and should be fixed
    },
    {
      target: (
        local svc_info = (import '../grafana-loki/_app_config.json');
        {
          name: svc_info.service_account_name + '-test-rw-binding',
          application: (
            {
              namespace: svc_info.namespace,
              serviceaccount: svc_info.service_account_name,
            }
          )
        }
      ),
      policy: 'test-rw',
    },
  ]
]
