local lib_hash = (import '../../../jsonnetlib/hash.libsonnet');

local name = (import 'config.json5').name;
local namespace = (import 'config.json5').namespace;

local app_name = name + '-helm';
local app_namespace = 'argocd';

local op_item = {
  apiVersion: 'onepassword.com/v1',
  kind: 'OnePasswordItem',
  metadata: {
    name: 'dummy',
  },
  spec: {
    // https://start.1password.com/open/i?a=UWWKBI7TBZCR7JIGGPATTRJZPQ&v=tsa4qdut6lvgsrl5xvsvdnmgwe&i=tibvxjoy34cu3sc5vhfri6cf2u&h=my.1password.com
    itemPath: 'vaults/tsa4qdut6lvgsrl5xvsvdnmgwe/items/tibvxjoy34cu3sc5vhfri6cf2u',
  },
};
local op_item_name = name + '-' + lib_hash {data: op_item}.output;

local helm_app = {
  apiVersion: 'argoproj.io/v1alpha1',
  kind: 'Application',
  metadata: {
    name: app_name,
    namespace: app_namespace,
  },
  spec: {
    project: 'default',
    destination: {
      server: 'https://kubernetes.default.svc',
      namespace: namespace,
    },
    syncPolicy: {
      automated: {
        selfHeal: true,
        prune: true,
      },
      syncOptions: [
        'CreateNamespace=true',
        'ServerSideApply=true',
        'FailOnSharedResource=true',
      ],
    },
    source: {
      // https://github.com/grafana/helm-charts/tree/main/charts/grafana
      // https://artifacthub.io/packages/helm/grafana/grafana
      repoURL: 'https://grafana.github.io/helm-charts',
      chart: 'grafana',
      targetRevision: '9.2.9',
      helm: {
        releaseName: name,
        valuesObject: {
          persistence: {
            type: 'pvc',
            enabled: true,
          },
          admin: {
            existingSecret: op_item_name,
            userKey: 'username',
            passwordKey: 'password',
          },
          service: {
            enabled: true,
            type: 'ClusterIP',
          },
          affinity: {
            nodeAffinity: {
              requiredDuringSchedulingIgnoredDuringExecution: {
                nodeSelectorTerms: [
                  {
                    matchExpressions: [
                      {
                        key: 'storage.longhorn.pollenjp.com/enabled',
                        operator: 'In',
                        values: [
                          'true'
                        ]
                      }
                    ]
                  }
                ]
              }
            }
          },
          datasources: {
            'datasources.yaml': {
              apiVersion: 1,
              datasources: [
                {
                  name: 'Loki',
                  type: 'loki',
                  access: 'proxy',
                  orgId: 1,
                  // jsonData: {
                  //   httpHeaderName1: 'X-Scope-OrgID',
                  // },
                  // secureJsonData: {
                  //   httpHeaderValue1: '1',
                  // },
                  url: (
                    local n = (import '../grafana-loki/config.json5').name + '-gateway';
                    local ns = (import '../grafana-loki/config.json5').namespace;
                    'http://' + n + '.' + ns + '.svc.cluster.local'
                  ),
                  basicAuth: false,
                  isDefault: false,
                  version: 1,
                  editable: false,
                },
                {
                  name: 'Prometheus',
                  type: 'prometheus',
                  access: 'proxy',
                  orgId: 1,
                  url: (
                    local n = (import '../grafana-prometheus/config.json5').name + '-server';
                    local ns = (import '../grafana-prometheus/config.json5').namespace;
                    'http://' + n + '.' + ns + '.svc.cluster.local'
                  ),
                  isDefault: false,
                  version: 1,
                  editable: false,
                },
              ],
            },
          },
        },
      },
    },
  },
};

[
  std.mergePatch(op_item, { metadata: { name: op_item_name } }),
  helm_app,
]
