local name = (import 'config.json5').name;
local namespace = (import 'config.json5').namespace;

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
      // https://external-secrets.io/latest/introduction/getting-started/
      // https://github.com/external-secrets/external-secrets-helm-operator
      repoURL: 'https://charts.external-secrets.io',
      chart: 'external-secrets',
      targetRevision: '0.17.0',
      helm: {
        releaseName: name,
        valuesObject: {
          resources: {
            requests: {
              cpu: '10m',
              memory: '50Mi',
            },
          },
          webhook: {
            resources: {
              requests: {
                cpu: '10m',
                memory: '100Mi',
              },
            },
          },
          certController: {
            resources: {
              requests: {
                cpu: '2m',
                memory: '36Mi',
              },
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
