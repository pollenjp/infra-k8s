local lib_hash = (import '../../../jsonnetlib/hash.libsonnet');

local name = (import 'config.json5').name;
local namespace = (import 'config.json5').namespace;

local app_name = name + '-helm';
local app_namespace = 'argocd';

local node_affinity = {
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
      // https://github.com/prometheus-community/helm-charts
      // https://artifacthub.io/packages/helm/prometheus-community/prometheus
      repoURL: 'https://prometheus-community.github.io/helm-charts',
      chart: 'prometheus',
      targetRevision: '27.32.0',
      helm: {
        // https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus
        releaseName: name,
        valuesObject: {
          server: {
            persistentVolume: {
              size: '8Gi',
            },
            // Prometheus' data retention size. Supported units: B, KB, MB, GB, TB, PB, EB.
            retentionSize: '5GB',
            affinity: {
              nodeAffinity: node_affinity,
            },
          },
          // https://github.com/prometheus-community/helm-charts/blob/main/charts/alertmanager/values.yaml
          alertmanager: {
            affinity: {
              nodeAffinity: node_affinity,
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
