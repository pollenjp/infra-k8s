local lib_hash2 = (import '../../../jsonnetlib/hash2.libsonnet');

local name = (import 'config.json5').name;
local namespace = (import 'config.json5').namespace;

local app_name = name + '-helm';
local app_namespace = 'argocd';

// https://github.com/grafana/loki/blob/9dd14ba589a816470634582faaddd7e1aba2a069/production/helm/loki/Chart.yaml#L16
// -> minio helm chart version: 5.4.0
local loki_chart_version = '6.30.1';
// https://github.com/minio/minio/blob/b4b3d208dd7dad1ac67ce662412b89b0d70d68b6/helm/minio/values.yaml#L13-L29
local minio_image = {
  // repository: 'quay.io/minio/minio',
  tag: 'RELEASE.2024-12-18T13-15-44Z-cpuv1', // need '-cpuv1'
};
local minio_mc_image = {
  // repository: 'quay.io/minio/mc',
  tag: 'RELEASE.2024-11-21T17-21-54Z-cpuv1', // need '-cpuv1'
};

local minio_ex_secret = lib_hash2 { data: {
  apiVersion: 'external-secrets.io/v1',
  kind: 'ExternalSecret',
  metadata: {
    name: (import 'config.json5').name + '-ex-secret',
  },
  spec: {
    secretStoreRef: {
      kind: 'ClusterSecretStore',
      name: (import '../external-secrets/secret_store.jsonnet').metadata.name,
    },
    target: {
      creationPolicy: 'Owner',
    },
    data: [
      // https://github.com/minio/minio/blob/e1fcaebc77ef97bb212adcf764bd262e4155211a/helm/minio/values.yaml#L96-L106
      //
      // existingSecret
      // | Chart var             | .data.<key> in Secret    |
      // |:----------------------|:-------------------------|
      // | rootUser              | rootUser                 |
      // | rootPassword          | rootPassword             |
      //
      // https://start.1password.com/open/i?a=UWWKBI7TBZCR7JIGGPATTRJZPQ&v=tsa4qdut6lvgsrl5xvsvdnmgwe&i=ovkly32j3sw3on4qfs5uyp4aei&h=my.1password.com
      {
        secretKey: 'rootUser',
        remoteRef: {
          key: 'ovkly32j3sw3on4qfs5uyp4aei/6xvsukjqnua2qmfhfzrdx65fpa/gcl7whpcuvza5x5mjc6v2og6fm',
        },
      },
      {
        secretKey: 'rootPassword',
        remoteRef: {
          key: 'ovkly32j3sw3on4qfs5uyp4aei/6xvsukjqnua2qmfhfzrdx65fpa/acyadgpgfgsc6oao6otgi6gacu',
        },
      },
      // users[0].existingSecret
      {
        secretKey: 'user0_secret_key',
        remoteRef: {
          key: 'ovkly32j3sw3on4qfs5uyp4aei/6xvsukjqnua2qmfhfzrdx65fpa/2v3ydlsmkkalx562zcabwogbeq',
        },
      }
    ]
  },
} }.output;

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
      // https://github.com/grafana/loki/tree/main/production/helm/loki
      // https://artifacthub.io/packages/helm/grafana/loki
      repoURL: 'https://grafana.github.io/helm-charts',
      chart: 'loki',
      targetRevision: loki_chart_version,
      helm: {
        releaseName: name,
        valuesObject: {
          loki: {
            auth_enabled: false,
            storage: {
              type: 's3',
              // bucketNames: {
              //   // TODO: https://github.com/grafana/loki/blob/755e9fc14fd3a1a609e897515d9f04553a6407a5/production/helm/loki/values.yaml#L361-L366
              //   chunks: 'loki-chunks',
              //   ruler: 'loki-ruler',
              //   admin: 'loki-admin',
              // },
              s3: {
                type: 's3',
                endpoint: 'http://' + name + '-minio.' + namespace + '.svc.cluster.local:9000',
                insecure: true,
                http_config: {
                  insecure_skip_verify: true,
                },
                // accessKeyId: '',
                // secretAccessKey: '',
              },
            },
            // storage_config: {
            //   aws: {
            //     // endpoint: 'http://' + namespace + '.' + name + '-minio.svc.cluster.local:9000',
            //     s3: 'http://' + namespace + '.' + name + '-minio.svc.cluster.local:9000/loki',
            //     insecure: true,
            //     access_key: '',
            //     secret_access_key: '',
            //   }
            // },
            schemaConfig: {
              configs: [
                // {
                //   from: '2025-06-01',
                //   store: 'tsdb',
                //   object_store: 'filesystem',
                //   schema: 'v13',
                //   index: {
                //     prefix: 'loki_index_',
                //     period: '24h',
                //   },
                // },
                {
                  from: '2025-06-12',
                  store: 'tsdb',
                  object_store: 's3',
                  schema: 'v13',
                  index: {
                    prefix: 'loki_index_',
                    period: '24h',
                  },
                },
              ],
            },
            ingester: {
              chunk_encoding: 'snappy',
            },
            querier: {
              max_concurrent: 4,
            },
            pattern_ingester: {
              enabled: true,
            },
            limits_config: {
              allow_structured_metadata: true,
              volume_enabled: true,
            },
          },
          deploymentMode: 'SimpleScalable',
          backend: {
            replicas: 2,
            affinity: {
              nodeAffinity: node_affinity,
            },
          },
          read: {
            replicas: 2,
          },
          write: {
            // replicas: 3, // To ensure data durability with replication
            replicas: 2,
            affinity: {
              nodeAffinity: node_affinity,
            },
          },
          minio: {
            // https://github.com/minio/minio/tree/master/helm/minio
            enabled: true,
            image: minio_image,
            mcImage: minio_mc_image,
            // persistence: {
            //   size: '50Gi',
            // },
            //
            // https://github.com/minio/minio/blob/f0b91e5504663c4672da451877857b57c3345295/helm/minio/values.yaml#L96-L106
            // https://github.com/grafana/loki/blob/755e9fc14fd3a1a609e897515d9f04553a6407a5/production/helm/loki/values.yaml#L3476-L3478
            existingSecret: minio_ex_secret.metadata.name,
            users: [
              // https://github.com/minio/minio/blob/f0b91e5504663c4672da451877857b57c3345295/helm/minio/values.yaml#L369-L382
              //
              // https://github.com/grafana/loki/blob/755e9fc14fd3a1a609e897515d9f04553a6407a5/production/helm/loki/values.yaml#L3479-L3485
              // > The first user in the list below is used for Loki/GEL authentication.
              // > You can add additional users if desired; they will not impact Loki/GEL.
              // > `accessKey` = username, `secretKey` = password
              {
                accessKey: 'logs-user',
                existingSecret: minio_ex_secret.metadata.name,
                existingSecretKey: 'user0_secret_key',
                policy: 'readwrite',
              }
            ],
            resources: {
              requests: {
                memory: '1Gi',
              },
            },
            affinity: {
              nodeAffinity: node_affinity,
            }
          },
          // gateway: {
          //   service: {
          //     type: 'LoadBalancer',
          //   },
          // },
          chunksCache: {
            allocatedMemory: 4096,
          }
        },
      },
    },
  },
};

[
  minio_ex_secret,
  helm_app,
]
