local lib_hash2 = import '../../../jsonnetlib/hash2.libsonnet';

local name = (import '_config.jsonnet').name;
local export_svc_name = (import '_config.jsonnet').export_svc_name;
local export_svc_port = (import '_config.jsonnet').export_svc_port;

local agent_data_pvc = {
  apiVersion: "v1",
  kind: "PersistentVolumeClaim",
  metadata: {
    name: name + '-data-pvc',
    labels: {
      app: name,
      tier: 'database',
    }
  },
  spec: {
    accessModes: ["ReadWriteOnce"],
    resources: {
      requests: {
        storage: "10Gi"
      },
    },
  },
};

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

local agent_pod_app_label = name + '-agent-pod';
local agent_deployment = {
  apiVersion: 'apps/v1',
  kind: 'Deployment',
  metadata: {
    name: name + '-agent',
    labels: {
      'app.kubernetes.io/name': name,
    },
  },
  spec: {
    replicas: 1,
    selector: {
      matchLabels: {
        'app': agent_pod_app_label,
        'app.kubernetes.io/name': name,
      },
    },
    template: {
      metadata: {
        labels: {
          'app': agent_pod_app_label,
          'app.kubernetes.io/name': name,
        },
      },
      spec: (
        local volume_name = name + '-agent--data';
        {
          securityContext: {
            // NOTE:
            // Mounted volumes are owned by root:root, so we need to change the
            // owner to the agent user
            runAsUser: 1000,
            runAsGroup: 3000,
            fsGroup: 3000,
          },
          containers: [
            {
              name: name + '-agent-container',
              image: 'mirror.gcr.io/kerberos/agent:v3.3.19',
              imagePullPolicy: 'Always',
              ports: [
                {
                  containerPort: 80,
                  protocol: 'TCP',
                },
              ],
              volumeMounts: [
                {
                  name: volume_name,
                  mountPath: '/home/agent/data/config',
                  subPath: 'config',
                },
                {
                  name: volume_name,
                  mountPath: '/home/agent/data/recordings',
                  subPath: 'recordings',
                },
                {
                  name: volume_name,
                  mountPath: '/home/agent/data/snapshots',
                  subPath: 'snapshots',
                },
                {
                  name: volume_name,
                  mountPath: '/home/agent/data/cloud',
                  subPath: 'cloud',
                },
              ],
            },
          ],
          initContainers: [
            {
              name: name + '-init',
              image: 'mirror.gcr.io/kerberos/agent:v3.3.19',
              imagePullPolicy: 'Always',
              command: [
                "sh",
                "-c",
                "id && ls -la /home/agent/data/config && cp /home/agent/data/config.template.json /home/agent/data/config/config.json",
              ],
              volumeMounts: [
                {
                  name: volume_name,
                  mountPath: '/home/agent/data/config',
                  subPath: 'config',
                },
              ],
            },
          ],
          volumes: [
            {
              name: volume_name,
              persistentVolumeClaim: {
                claimName: agent_data_pvc.metadata.name,
              },
            }
          ],
          affinity: {
            nodeAffinity: node_affinity,
          },
        }
      ),
    },
  },
};

local agent_service = {
  apiVersion: 'v1',
  kind: 'Service',
  metadata: {
    name: export_svc_name,
    labels: {
      'app.kubernetes.io/name': name,
    },
  },
  spec: {
    selector: {
      'app': agent_pod_app_label,
    },
    ports: [
      {
        port: export_svc_port,
        protocol: 'TCP',
        targetPort: 80,
      },
    ],
  },
};

[
  agent_data_pvc,
  agent_deployment,
  agent_service,
]
