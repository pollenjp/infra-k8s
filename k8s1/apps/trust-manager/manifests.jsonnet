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
      // https://github.com/cert-manager/trust-manager/tree/main/deploy/charts/trust-manager
      repoURL: 'https://charts.jetstack.io',
      chart: 'trust-manager',
      targetRevision: '0.19.0',
      helm: {
        releaseName: name,
        valuesObject: {
          // https://github.com/cert-manager/trust-manager/blob/48852a0f406b9d569164aded77ec19e475373938/deploy/charts/trust-manager/values.yaml#L237-L240
          // https://github.com/cert-manager/trust-manager/issues/60#issuecomment-1377312905
          app: {
            trust: {
              namespace: namespace,
            }
          },
          secretTargets: {
            enabled: true,
            authorizedSecrets: [
              (import './minio-ca-cert.jsonnet').metadata.name,
            ]
          },
        },
      },
    },
  },
};

[
  helm_app,
]
