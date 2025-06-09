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
      // https://artifacthub.io/packages/helm/grafana/loki
      repoURL: 'https://grafana.github.io/helm-charts',
      chart: 'loki',
      targetRevision: loki_chart_version,
      helm: {
        releaseName: name,
        valuesObject: {
          loki: {
            auth_enabled: false,
            schemaConfig: {
              configs: [
                {
                  from: '2025-06-01',
                  store: 'tsdb',
                  // object_store: 's3',
                  object_store: 'filesystem',
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
          },
          read: {
            replicas: 2,
          },
          write: {
            // replicas: 3, // To ensure data durability with replication
            replicas: 2,
          },
          minio: {
            enabled: true,
            image: minio_image,
            mcImage: minio_mc_image,
          },
          gateway: {
            service: {
              type: 'LoadBalancer',
            },
          },
          chunksCache: {
            allocatedMemory: 4096,
          }
        },
      },
    },
  },
};

[
  helm_app,
]
