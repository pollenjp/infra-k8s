local name = (import '_app_config.json').name;
local namespace = (import '_app_config.json').namespace;
local app_name = name + '-helm';
local app_namespace = 'argocd';

// https://cert-manager.io/docs/installation/helm/

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
      // https://artifacthub.io/packages/helm/cert-manager/cert-manager
      repoURL: 'https://charts.jetstack.io',
      chart: 'cert-manager',
      targetRevision: 'v1.19.1',
      helm: {
        releaseName: name,
        valuesObject: {
          crds: {
            enabled: true,
            keep: true,
          },
          // prometheus: {
          //   servicemonitor: {
          //     enabled: true,
          //   },
          // }
        },
      },
    },
  },
};

[
  helm_app,
]
