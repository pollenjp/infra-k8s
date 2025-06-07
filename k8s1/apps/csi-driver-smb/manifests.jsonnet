local name = (import 'config.json5').name;
local namespace = (import 'config.json5').namespace;

local app_name = name + '-helm';
local app_namespace = 'argocd';

local env = (import '../../env.jsonnet');
local lib_hash = (import '../../../jsonnetlib/hash.libsonnet');

local helm = {
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
      repoURL: 'https://raw.githubusercontent.com/kubernetes-csi/csi-driver-smb/master/charts',
      chart: 'csi-driver-smb',
      targetRevision: 'v1.18.0',
      helm: {
        releaseName: name,
        values: (importstr 'values.yaml'),
      },
    },
  },
};

local op_item_spec = {
  // https://start.1password.com/open/i?a=UWWKBI7TBZCR7JIGGPATTRJZPQ&v=tsa4qdut6lvgsrl5xvsvdnmgwe&i=rvybz6bamkrlwpiwqrqfm74w4e&h=my.1password.com
  item: 'vaults/tsa4qdut6lvgsrl5xvsvdnmgwe/items/rvybz6bamkrlwpiwqrqfm74w4e',
};
local secret_name = name + '-secret-' + lib_hash { data: op_item_spec }.output;
local storage_class = {
  apiVersion: 'storage.k8s.io/v1',
  kind: 'StorageClass',
  metadata: {
    name: 'smb',
    namespace: namespace,
    annotations: {
      'storageclass.kubernetes.io/is-default-class': 'true',
    },
  },
  provisioner: 'smb.csi.k8s.io',
  parameters: {
    source: '//192.168.100.90/disk1',
    subdir: 'k8s1-storage-class',
    onDelete: 'delete', // FIXME: check
    'csi.storage.k8s.io/provisioner-secret-name': secret_name,
    'csi.storage.k8s.io/provisioner-secret-namespace': namespace,
    'csi.storage.k8s.io/node-stage-secret-name': secret_name,
    'csi.storage.k8s.io/node-stage-secret-namespace': namespace,
  },
  volumeBindingMode: 'Immediate',
  allowVolumeExpansion: true,
  mountOptions: [
    'dir_mode=0777',
    'file_mode=0777',
    'uid=1001',
    'gid=1001',
    'noperm',
    'mfsymlinks',
    'cache=strict',
    'noserverino',  # required to prevent data corruption
  ],
};

// only for secret
local deployment = {
  apiVersion: 'apps/v1',
  kind: 'Deployment',
  metadata: {
    name: name,
    namespace: namespace,
    annotations: {
      // FIXME: busybox is useless
      'operator.1password.io/item-path': op_item_spec.item,
      'operator.1password.io/item-name': secret_name,
    },
  },
  spec: {
    replicas: 1,
    selector: {
      matchLabels: {
        app: 'busybox',
      },
    },
    template: {
      metadata: {
        labels: {
          app: 'busybox',
        },
      },
      spec: {
        containers: [
          {
            name: 'busybox',
            image: 'mirror.gcr.io/library/busybox:latest',
            imagePullPolicy: 'IfNotPresent',
            command: ['sleep', 'infinity'],
          },
        ],
      },
    },
  },
};

[
  helm,
  storage_class,
  deployment,
]
