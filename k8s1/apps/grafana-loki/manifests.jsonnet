local lib_hash2 = (import '../../../jsonnetlib/hash2.libsonnet');

local name = (import 'config.json5').name;
local namespace = (import 'config.json5').namespace;
local service_account_name = (import 'config.json5').service_account_name;

local minio_tenant = (import '../minio-tenant-1/config.json5');
local minio_operator = (import '../minio-operator/config.json5');

local app_name = name + '-helm';
local app_namespace = 'argocd';

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

local sts_token_name = 'minio-sts-token';
local sts_token_path = '/var/run/secrets/sts.min.io/serviceaccount/token';

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
      targetRevision: '6.37.0',
      helm: {
        releaseName: name,
        valuesObject: {
          loki: {
            auth_enabled: false,
            serviceAccount: {
              // Define clearly for policy binding
              // https://github.com/grafana/loki/blob/755e9fc14fd3a1a609e897515d9f04553a6407a5/production/helm/loki/templates/_helpers.tpl#L147-L156^C
              name: service_account_name,
            },
            storage: {
              type: 's3',
              bucketNames: {
                // https://github.com/grafana/loki/blob/755e9fc14fd3a1a609e897515d9f04553a6407a5/production/helm/loki/values.yaml#L361-L366
                // TODO: modify hard coding
                chunks: 'loki-chunks',
                ruler: 'loki-ruler',
                admin: 'loki-admin',
              },
              s3: {
                type: 's3',
                endpoint: 'http://minio.' + minio_tenant.namespace + '.svc.cluster.local:80',
                insecure: true,
                http_config: {
                  insecure_skip_verify: true,
                },
                // https://github.com/minio/operator/blob/e054c34ee36535b1323337816450dd7b3fcac482/pkg/controller/sts.go#L269-L271
                sts_endpoint: 'https://sts.' + minio_operator.namespace + '.svc.cluster.local:4223/sts/' + minio_tenant.namespace,
                // https://docs.aws.amazon.com/AmazonS3/latest/userguide/VirtualHosting.html#path-style-access
                bucket_lookup_type: 'path',
              },
            },
            schemaConfig: {
              configs: [
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
          // gateway: {
          //   service: {
          //     type: 'LoadBalancer',
          //   },
          // },
          chunksCache: {
            allocatedMemory: 4096,
          },
          global: {
            extraEnv: [
              {
                // https://github.com/grafana/loki/blob/755e9fc14fd3a1a609e897515d9f04553a6407a5/vendor/github.com/minio/minio-go/v7/pkg/credentials/iam_aws.go#L124
                // https://github.com/grafana/loki/blob/755e9fc14fd3a1a609e897515d9f04553a6407a5/vendor/github.com/minio/minio-go/v7/pkg/credentials/iam_aws.go#L158-L190
                // Current minio requires this env var to use STS WebIdentity? (@pollenjp)
                name: 'AWS_WEB_IDENTITY_TOKEN_FILE',
                value: sts_token_path,
              },
              {
                // RoleARN is required field
                // https://github.com/grafana/loki/blob/755e9fc14fd3a1a609e897515d9f04553a6407a5/vendor/github.com/aws/aws-sdk-go-v2/config/resolve_credentials.go#L480-L482
                name: 'AWS_ROLE_ARN',
                // https://github.com/minio/minio/blob/f0b91e5504663c4672da451877857b57c3345295/internal/arn/arn.go#L27-L40
                // arn:partition:service:region:account-id:resource-type/resource-id
                // - empty region
                // - empty account-id
                value: 'arn:minio:iam:::role/dummy', // dummy role arn
              },
            ],
            extraVolumes: [
              {
                // https://github.com/minio/operator/security/advisories/GHSA-7m6v-q233-q9j9
                name: sts_token_name,
                projected: {
                  sources: [
                    {
                      serviceAccountToken: {
                        audience: 'sts.min.io',
                        expirationSeconds: 86400, // 1 day
                        path: std.splitLimitR(sts_token_path, '/', 1)[1],
                      }
                    }
                  ],
                },
              },
            ],
            extraVolumeMounts: [
              {
                name: sts_token_name,
                mountPath: std.splitLimitR(sts_token_path, '/', 1)[0],
                readOnly: true,
              },
            ],
          },
        },
      },
    },
  },
};

[
  minio_ex_secret,
  helm_app,
]
