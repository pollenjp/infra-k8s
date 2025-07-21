local name = (import 'config.json5').name;
local namespace = (import 'config.json5').namespace;
local public_domain = (import 'config.json5').public_domain;

local pod_name = name + '-pod';
local container_name = name + '-container';
local deployment_name = name + '-deployment';
local service_name = name;
local ingress_name = name;

local issuer_name = (import '../letsencrypt-stg-issuer/config.json5').name;

local op_item_spec = {
  // https://start.1password.com/open/i?a=UWWKBI7TBZCR7JIGGPATTRJZPQ&v=tsa4qdut6lvgsrl5xvsvdnmgwe&i=rvybz6bamkrlwpiwqrqfm74w4e&h=my.1password.com
  item: 'vaults/tsa4qdut6lvgsrl5xvsvdnmgwe/items/rvybz6bamkrlwpiwqrqfm74w4e',
};
local env = (import '../../env.jsonnet');
local lib_hash = (import '../../../jsonnetlib/hash.libsonnet');
local lib_hash2 = (import '../../../jsonnetlib/hash2.libsonnet');
local secret_name = name + '-smbcreds-' + lib_hash2 { data: op_item_spec }.output;

// https://github.com/kubernetes-csi/csi-driver-smb/blob/master/docs/driver-parameters.md

local pv = lib_hash2 { data: {
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
}}.output;

local pvc = lib_hash2 { data: {
  apiVersion: 'v1',
  kind: 'PersistentVolumeClaim',
  metadata: {
    name: name,
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
}}.output;

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
              claimName: pvc.metadata.name,
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

local ingress = {
  apiVersion: 'networking.k8s.io/v1',
  kind: 'Ingress',
  metadata: {
    name: ingress_name,
    annotations: {
      'cert-manager.io/cluster-issuer': issuer_name,
    },
  },
  spec: {
    rules: [
      {
        host: public_domain,
        http: {
          paths: [
            {
              path: '/',
              pathType: 'Prefix',
              backend: {
                service: {
                  name: service_name,
                  port: {
                    number: service.spec.ports[0].targetPort,
                  },
                },
              }
            }
          ]
        }
      }
    ],
    tls: [
      {
        hosts: [
          public_domain,
        ],
        secretName: public_domain + '-tls',
      }
    ]
  }
};

[
  pv,
  pvc,
  deployment,
  service,
  ingress,
]
