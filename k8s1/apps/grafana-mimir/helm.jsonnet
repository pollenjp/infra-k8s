local config = (import '_config.jsonnet');

local name = config.name;
local namespace = config.namespace;
local service_account_name = config.service_account_name;
local buckets = config.buckets;

local app_name = name + '-helm';
local app_namespace = 'argocd';

local minio_tenant = (import '../minio-tenant-1/_app_config.json');
local minio_operator = (import '../minio-operator/_app_config.json');

local internal_ca_configmap = (import '../trust-manager/trust-bundle.jsonnet');
local internal_ca_bundle_volume_name = 'internal-trust-bundle';
// local internal_ca_path = '/tls/internal/' + internal_ca_configmap.spec.target.configMap.key;
local internal_ca_path = '/etc/ssl/certs/' + internal_ca_configmap.spec.target.configMap.key;

local sts_token_name = 'minio-sts-token';
local sts_token_path = '/var/run/secrets/sts.min.io/serviceaccount/token';

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
      // https://github.com/grafana/mimir/tree/main/operations/helm/charts/mimir-distributed
      repoURL: 'https://grafana.github.io/helm-charts',
      chart: 'mimir-distributed',
      targetRevision: '5.9.0-weekly.359',
      helm: {
        releaseName: name,
        valuesObject: {
          serviceAccount: {
            // https://github.com/grafana/mimir/blob/b8771766403c9b7028055591c2ec18163a808e70/operations/helm/charts/mimir-distributed/values.yaml#L80
            name: service_account_name,
          },
          alertmanager: {
            affinity: {
              nodeAffinity: node_affinity,
            },
          },
          ingester: {
            zoneAwareReplication: {
              enabled: false,
            },
            affinity: {
              nodeAffinity: node_affinity,
            },
            resources: {
              requests: {
                cpu: '10m',
                memory: '128Mi',
              },
            },
          },
          store_gateway: {
            zoneAwareReplication: {
              enabled: false,
            },
            affinity: {
              nodeAffinity: node_affinity,
            },
            resources: {
              requests: {
                cpu: '10m',
                memory: '128Mi',
              },
            },
          },
          compactor: {
            affinity: {
              nodeAffinity: node_affinity,
            },
            resources: {
              requests: {
                cpu: '10m',
                memory: '128Mi',
              },
            },
          },
          kafka: {
            // enabled: false,
            persistence: {
              size: '5Gi',
            },
            affinity: {
              nodeAffinity: node_affinity,
            },
            resources: {
              requests: {
                cpu: '10m',
                memory: '128Mi',
              },
            },
            extraEnv: [
              {
                name: 'KAFKA_LOG_RETENTION_BYTES',
                value: '268435456', // 256 MiB
                // value: '1073741824', // 1GiB
                // value: '4294967296', // 4GiB
              },
              {
                name: 'KAFKA_LOG_SEGMENT_BYTES',
                value: '134217728', // 128 MiB
              },
              {
                // log.cleaner.delete.retention.ms
                name: 'KAFKA_LOG_CLEANER_DELETE_RETENTION_MS',
                value: '300000', // 5 minutes
              },
              {
                name: 'KAFKA_LOG_CLEANUP_POLICY',
                value: 'delete', // specify clearly
              },
              {
                name: 'KAFKA_LOG_RETENTION_MINUTES',
                value: '60',
              },
            ],
          },
          rollout_operator: {
            // Failed sync attempt to 5.9.0-weekly.359: one or more objects failed to apply,
            // reason:
            //   Internal error occurred:
            //   failed calling webhook "prepare-downscale-mimir.grafana.com":
            //   failed to call webhook: Post "https://mimir-rollout-operator.mimir.svc:443/admission/prepare-downscale?timeout=10s":
            //   tls: failed to verify certificate:
            //   x509: certificate is valid for rollout-operator.mimir.svc, not mimir-rollout-operator.mimir.svc
            webhooks: {
              enabled: false,
            },
          },
          gateway: {
            // https://github.com/grafana/mimir/blob/b8771766403c9b7028055591c2ec18163a808e70/operations/helm/charts/mimir-distributed/templates/gateway/_helpers.tpl#L16-L22
            enabledNonEnterprise: true,
          },
          minio: {
            enabled: false,
          },
          mimir: {
            // https://github.com/grafana/mimir/blob/b8771766403c9b7028055591c2ec18163a808e70/operations/helm/charts/mimir-distributed/values.yaml#L462-L480
            structuredConfig: {
              common: {
                storage: {
                  s3: {
                    bucket_name: buckets.common_storage,
                    endpoint: 'minio.' + minio_tenant.namespace + '.svc.cluster.local:80',
                    insecure: true,
                    // https://github.com/grafana/loki/blob/cadc8240153597608b59821047345064981d1019/pkg/storage/bucket/s3/config.go#L77
                    http: {
                      insecure_skip_verify: true,
                      tls_ca_path: internal_ca_path,
                    },
                    // https://github.com/minio/operator/blob/e054c34ee36535b1323337816450dd7b3fcac482/pkg/controller/sts.go#L269-L271
                    sts_endpoint: 'https://sts.' + minio_operator.namespace + '.svc.cluster.local:4223/sts/' + minio_tenant.namespace,
                    // https://docs.aws.amazon.com/AmazonS3/latest/userguide/VirtualHosting.html#path-style-access
                    bucket_lookup_type: 'path',
                  },
                },
              },
              limits: {
                max_global_series_per_user: 2000000,
              },
              alertmanager_storage: {
                backend: 's3',
                s3: {
                  bucket_name: buckets.alertmanager_storage,
                },
              },
              blocks_storage: {
                backend: 's3',
                s3: {
                  bucket_name: buckets.blocks_storage,
                },
              },
              ruler_storage: {
                backend: 's3',
                s3: {
                  bucket_name: buckets.ruler_storage,
                },
              },
            },
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
                value: 'arn:minio:iam:::policy/readwrite', // dummy value
              },
              {
                name: 'AWS_CA_BUNDLE',
                value: internal_ca_path,
              }
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
              {
                name: internal_ca_bundle_volume_name,
                configMap: {
                  name: internal_ca_configmap.metadata.name,
                },
              }
            ],
            extraVolumeMounts: [
              {
                name: sts_token_name,
                mountPath: std.splitLimitR(sts_token_path, '/', 1)[0],
                readOnly: true,
              },
              {
                name: internal_ca_bundle_volume_name,
                mountPath: std.splitLimitR(internal_ca_path, '/', 1)[0],
                readOnly: true,
              }
            ],
          },
        },
      },
    },
  },
};

[
  helm_app,
]
