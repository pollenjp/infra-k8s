local config = (import '_config.jsonnet');

local name = config.name;
local namespace = config.namespace;

local app_name = name + '-helm';
local app_namespace = 'argocd';

local ex_secret = (import 'external-secret.jsonnet');

local node_affinity = {
  requiredDuringSchedulingIgnoredDuringExecution: {
    nodeSelectorTerms: [
      {
        matchExpressions: [
          {
            // nodes having disk allocation capability
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
};

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
      // https://docs.goauthentik.io/install-config/install/kubernetes/
      repoURL: 'https://charts.goauthentik.io',
      chart: 'authentik',
      targetRevision: '2025.8.3',
      helm: {
        releaseName: name,
        valuesObject: {
          global: {
            affinity: {
              nodeAffinity: node_affinity,
            },
            env: [
              {
                // https://github.com/goauthentik/authentik/blob/68292fede2e413cf96a20dcf13cd55e6c2164620/internal/config/struct.go#L11-L12
                name: 'AUTHENTIK_SECRET_KEY',
                valueFrom: {
                  secretKeyRef: {
                    name: ex_secret.metadata.name,
                    key: config.secrets.authentik_secret_key.key_name,
                  }
                }
              },
              {
                // https://github.com/goauthentik/authentik/blob/68292fede2e413cf96a20dcf13cd55e6c2164620/website/docs/install-config/configuration/configuration.mdx#L75
                name: 'AUTHENTIK_POSTGRESQL__PASSWORD',
                valueFrom: {
                  secretKeyRef: {
                    name: ex_secret.metadata.name,
                    key: config.secrets.psql_user.key_name,
                  }
                }
              },
            ],
          },
          authentic: {
          },
          server: {
          },
          worker: {
          },
          postgresql: {
            enabled: true,
            auth: {
              // https://github.com/bitnami/charts/blob/bf43666619d60297e22479b22966a3cd9546d8f9/bitnami/postgresql/values.yaml#L170-L178
              existingSecret: ex_secret.metadata.name,
              secretKeys: {
                adminPasswordKey: config.secrets.psql_admin.key_name,
                userPasswordKey: config.secrets.psql_user.key_name,
                replicationPasswordKey: config.secrets.psql_replication.key_name,
              },
            },
          },
          redis: {
            enabled: true,
          },
        },
      },
    },
  },
};

[
  helm_app,
]
