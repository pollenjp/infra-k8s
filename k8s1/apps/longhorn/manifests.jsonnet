local name = (import 'config.json5').name;
local namespace = (import 'config.json5').namespace;
local storage_class_name = (import 'config.json5').storage_class_name;

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
      // https://charts.longhorn.io/
      repoURL: 'https://charts.longhorn.io',
      chart: 'longhorn',
      targetRevision: '1.9.0',
      helm: {
        releaseName: name,
        valuesObject: {
          preUpgradeChecker: {
            jobEnabled: false,
          }
        },
      },
    },
  },
};

local storage_class = {
  apiVersion: 'storage.k8s.io/v1',
  kind: 'StorageClass',
  metadata: {
    name: storage_class_name,
    namespace: namespace,
    annotations: {
      'storageclass.kubernetes.io/is-default-class': 'true',
    },
  },
  provisioner: 'driver.longhorn.io',
  allowVolumeExpansion: true,
  parameters: {
    numberOfReplicas: '1',
    dataLocality: 'best-effort',
    reclaimPolicy: 'Retain',
    staleReplicaTimeout: '30',
    fromBackup: '',
  },
};

[
  helm_app,
  storage_class,
]
