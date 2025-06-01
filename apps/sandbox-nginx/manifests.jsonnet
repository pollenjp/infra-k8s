local pod_name = (import 'config.json5').name + '-pod';
local container_name = (import 'config.json5').name + '-container';
local deployment_name = (import 'config.json5').name + '-deployment';
local service_name = (import 'config.json5').name + '-svc';
local pv_name = (import 'config.json5').name + '-pv';
local pvc_name = (import 'config.json5').name + '-pvc';
local namespace = (import 'config.json5').namespace;
local secret_name = 'smbcreds';

local deployment = {
  apiVersion: 'apps/v1',
  kind: 'Deployment',
  metadata: {
    name: deployment_name,
    labels: {
      'app.kubernetes.io/name': deployment_name,
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
                mountPath: '/var/www/html',
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

local onepassword_item = {
  apiVersion: 'onepassword.com/v1',
  kind: 'OnePasswordItem',
  metadata: {
    name: secret_name,
  },
  spec: {
    // https://start.1password.com/open/i?a=UWWKBI7TBZCR7JIGGPATTRJZPQ&v=tsa4qdut6lvgsrl5xvsvdnmgwe&i=rvybz6bamkrlwpiwqrqfm74w4e&h=my.1password.com
    item: 'vaults/tsa4qdut6lvgsrl5xvsvdnmgwe/items/rvybz6bamkrlwpiwqrqfm74w4e',
  },
};

local pv = {
  apiVersion: 'v1',
  kind: 'PersistentVolume',
  metadata: {
    name: pv_name,
  },
  spec: {
    capacity: {
      storage: '1Gi',
    },
    accessModes: [
      'ReadWriteMany',
    ],
    persistentVolumeReclaimPolicy: 'Retain',
    storageClassName: 'smb',
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
    csi: {
      driver: 'smb.csi.k8s.io',
      readOnly: false,
      volumeHandle: 'smb-server.' + namespace + '.svc.cluster.local/test-k8s1-disk',
      volumeAttributes: {
        source: '//192.168.100.90/test-k8s1-disk',
      },
      nodeStageSecretRef: {
        name: secret_name,
        namespace: namespace,
      },
    },
  },
};

local pvc = {
  apiVersion: 'v1',
  kind: 'PersistentVolumeClaim',
  metadata: {
    name: pvc_name,
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

[
  deployment,
  service,
  onepassword_item,
  pv,
  pvc,
]
