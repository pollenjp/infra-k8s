local name = (import 'config.json5').name;
local namespace = (import 'config.json5').namespace;

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
    // {
    //   target: (
    //     local svc_info = (import '../grafana-loki/config.json5');
    //     {
    //       name: svc_info.service_account_name + '-rw-binding',
    //       application: (
    //         {
    //           namespace: svc_info.namespace,
    //           serviceaccount: svc_info.service_account_name,
    //         }
    //       )
    //     }
    //   ),
    //   policy: 'readwrite',
    // },
    {
      target: (
        local svc_info = (import '../grafana-loki/config.json5');
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
