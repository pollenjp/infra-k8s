local name = (import 'config.json5').name;
local namespace = (import 'config.json5').namespace;

local pod_name = name + '-pod';
local container_name = name + '-container';
local deployment_name = name + '-deployment';
local service_name = name + '-svc';

local op_item_spec = {
  // https://start.1password.com/open/i?a=UWWKBI7TBZCR7JIGGPATTRJZPQ&v=tsa4qdut6lvgsrl5xvsvdnmgwe&i=rvybz6bamkrlwpiwqrqfm74w4e&h=my.1password.com
  item: 'vaults/tsa4qdut6lvgsrl5xvsvdnmgwe/items/rvybz6bamkrlwpiwqrqfm74w4e',
};
local secret_name = name + '-smbcreds-' + (import '../../jsonnetlib/hash.libsonnet') { data: op_item_spec }.output;

// https://github.com/kubernetes-csi/csi-driver-smb/blob/master/docs/driver-parameters.md

local pv = {
  apiVersion: 'v1',
  kind: 'PersistentVolume',
  metadata: {
    name: 'tmp',
  },
  spec: {
    capacity: {
      storage: '1Gi',
    },
    accessModes: [
      'ReadWriteMany',
    ],
    persistentVolumeReclaimPolicy: 'Delete',
    storageClassName: 'smb',
    mountOptions: [
      'dir_mode=0777',
      'file_mode=0777',
      // 'uid=1001',
      // 'gid=1001',
      // 'noperm',
      // 'mfsymlinks',
      // 'cache=strict',
      // 'noserverino',  # required to prevent data corruption
    ],
    csi: {
      driver: 'smb.csi.k8s.io',
      readOnly: false,
      // A recommended way to produce a unique value is to combine the smb-server address,
      // sub directory name and share name: {smb-server-address}#{sub-dir-name}#{share-name}.
      volumeHandle: '192.168.100.90#test-k8s1-disk#disk1',
      volumeAttributes: {
        source: '//192.168.100.90/disk1',
        subDir: 'test-k8s1-disk'
      },
      nodeStageSecretRef: {
        name: secret_name,
        namespace: namespace,
      },
    },
  },
};
local pv_name = name + '-' + (import '../../jsonnetlib/hash.libsonnet') { data: pv }.output;

local pvc = {
  apiVersion: 'v1',
  kind: 'PersistentVolumeClaim',
  metadata: {
    name: 'tmp',
  },
  spec: {
    accessModes: [
      'ReadWriteMany',
    ],
    resources: {
      requests: {
        storage: '500Mi',
      },
    },
    storageClassName: 'smb',
  },
};
local pvc_name = name + '-' + (import '../../jsonnetlib/hash.libsonnet') { data: pvc }.output;

local deployment = {
  apiVersion: 'apps/v1',
  kind: 'Deployment',
  metadata: {
    name: deployment_name,
    labels: {
      'app.kubernetes.io/name': deployment_name,
    },
    annotations: {
      'operator.1password.io/item-path': op_item_spec.item,
      'operator.1password.io/item-name': secret_name,
    },
  },
  spec: {
    replicas: 1,
    selector: {
      matchLabels: {
        app: pod_name,
      },
    },
    template: {
      metadata: {
        labels: {
          app: pod_name,
          'app.kubernetes.io/name': pod_name,
        },
      },
      spec: {
        containers: [
          {
            name: container_name,
            image: 'mirror.gcr.io/library/nginx:latest',
            imagePullPolicy: 'Always',
            ports: [
              {
                containerPort: 80,
              },
            ],
            volumeMounts: [
              {
                name: 'www',
                mountPath: '/usr/share/nginx/html',
              },
            ],
          },
        ],
        volumes: [
          {
            name: 'www',
            persistentVolumeClaim: {
              claimName: pvc_name,
            },
          },
        ],
      },
    },
  },
};

local service = {
  apiVersion: 'v1',
  kind: 'Service',
  metadata: {
    name: service_name,
    labels: {
      'app.kubernetes.io/name': service_name,
    },
  },
  spec: {
    selector: {
      'app.kubernetes.io/name': pod_name,
    },
    ports: [
      {
        port: 8080,
        protocol: 'TCP',
        targetPort: 80,
      },
    ],
  },
};

[
  std.mergePatch(pv, { metadata: { name: pv_name } }),
  std.mergePatch(pvc, { metadata: { name: pvc_name } }),
  deployment,
  service,
]
