local lib_hash = (import '../../../jsonnetlib/hash.libsonnet');

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
      // https://github.com/prometheus-community/helm-charts?tab=readme-ov-file
      // https://artifacthub.io/packages/helm/prometheus-community/prometheus
      repoURL: 'https://prometheus-community.github.io/helm-charts',
      chart: 'prometheus',
      targetRevision: '27.20.0',
      helm: {
        releaseName: name,
        // valuesObject: {},
      },
    },
  },
};

[
  helm_app,
]
