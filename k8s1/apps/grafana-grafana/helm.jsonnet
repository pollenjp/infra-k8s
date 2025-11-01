local config = (import '_config.jsonnet');
local ex_secret = (import 'external-secret.jsonnet');

local name = config.name;
local namespace = config.namespace;

local app_name = name + '-helm';
local app_namespace = 'argocd';

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
            existingSecret: ex_secret.metadata.name,
            userKey: config.secret.admin_username.key_name,
            passwordKey: config.secret.admin_password.key_name,
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
                    local n = (import '../grafana-loki/_app_config.json').name + '-gateway';
                    local ns = (import '../grafana-loki/_app_config.json').namespace;
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
                    local n = (import '../grafana-prometheus/_app_config.json').name + '-server';
                    local ns = (import '../grafana-prometheus/_app_config.json').namespace;
                    'http://' + n + '.' + ns + '.svc.cluster.local'
                  ),
                  isDefault: false,
                  version: 1,
                  editable: false,
                },
                {
                  name: 'Mimir',
                  type: 'prometheus',
                  access: 'proxy',
                  orgId: 1,
                  url: (
                    local n = (import '../grafana-mimir/_config.jsonnet').name + '-gateway';
                    local ns = (import '../grafana-mimir/_config.jsonnet').namespace;
                    'http://' + n + '.' + ns + '.svc.cluster.local/prometheus'
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
  helm_app,
]
