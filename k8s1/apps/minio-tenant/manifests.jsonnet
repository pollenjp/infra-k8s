local lib_hash2 = (import '../../../jsonnetlib/hash2.libsonnet');

local name = (import 'config.json5').name;
local namespace = (import 'config.json5').namespace;

local app_name = name + '-helm';
local app_namespace = 'argocd';

local ex_secret = lib_hash2 { data: {
  apiVersion: 'external-secrets.io/v1',
  kind: 'ExternalSecret',
  metadata: {
    name: name + '-ex-secret',
  },
  spec: {
    secretStoreRef: {
      kind: 'ClusterSecretStore',
      name: (import '../external-secrets/secret_store.jsonnet').metadata.name,
    },
    target: {
      creationPolicy: 'Owner',
      template: {
        engineVersion: 'v2',
        data: {
          // https://github.com/minio/operator/blob/e054c34ee36535b1323337816450dd7b3fcac482/helm/tenant/values.yaml#L75-L122
          // https://github.com/minio/operator/blob/e054c34ee36535b1323337816450dd7b3fcac482/helm/tenant/templates/tenant-configuration.yaml#L16-L18
          'config.env': |||
            export MINIO_ROOT_USER={{ .rootUser }}
            export MINIO_ROOT_PASSWORD={{ .rootPassword }}
          |||,
        },
      }
    },
    data: [
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
    ],
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
      // https://github.com/minio/operator/tree/master/helm/tenant
      repoURL: 'https://operator.min.io/',
      chart: 'tenant',
      targetRevision: '7.1.1',
      helm: {
        releaseName: name,
        valuesObject: {
            tenant: {
              image: {
                // cpuv1
                // https://github.com/minio/minio/blob/b4b3d208dd7dad1ac67ce662412b89b0d70d68b6/helm/minio/values.yaml#L13-L29
                // repository: 'quay.io/minio/minio',
                tag: 'RELEASE.2025-04-08T15-41-24Z-cpuv1',
              },
              configSecret: {
                // https://github.com/minio/operator/blob/e054c34ee36535b1323337816450dd7b3fcac482/helm/tenant/values.yaml#L75-L122
                name: ex_secret.metadata.name,
                existingSecret: true,
              },
              affinity: {
                nodeAffinity: node_affinity,
              },
            }
        },
      },
    },
  },
};

[
  ex_secret,
  helm_app,
]
