local lib_hash2 = (import '../../../jsonnetlib/hash2.libsonnet');

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
      // https://github.com/minio/operator/tree/master/helm/operator
      repoURL: 'https://operator.min.io/',
      chart: 'operator',
      targetRevision: '7.1.1',
      helm: {
        releaseName: name,
        valuesObject: {
          operator: {
            env: [
              {
                name: "OPERATOR_STS_ENABLED",
                value: "on",
              },
              {
                // https://docs.min.io/community/minio-object-store/operations/cert-manager/cert-manager-operator.html#install-operator-with-auto-tls-disabled
                name: "OPERATOR_STS_AUTO_TLS_ENABLED",
                value: "off",
              },
            ],
            affinity: {
              nodeAffinity: node_affinity,
            },
          }
        },
      },
    },
  },
};

[
  helm_app,
]
