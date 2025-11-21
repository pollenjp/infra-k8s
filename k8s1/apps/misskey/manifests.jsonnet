local lib_hash = (import '../../../jsonnetlib/hash.libsonnet');
local lib_hash2 = (import '../../../jsonnetlib/hash2.libsonnet');

local name = (import 'config.json5').name;
local namespace = (import 'config.json5').namespace;
local public_domain = (import 'config.json5').public_domain;

local env = (import '../../env.jsonnet');
local issuer_name = (import '../letsencrypt-stg-issuer/config.json5').name;
local secret_store_name = (import '../external-secrets/secret_store.jsonnet').metadata.name;

local misskey_image = 'ghcr.io/misskey-dev/misskey:latest';
local postgres_image = 'postgres:16';
local redis_image = 'redis:7';

local pod_name = name + '-pod';
local misskey_container_name = name + '-container';
local misskey_service_name = name;
local misskey_ingress_name = name;
local misskey_deployment_name = name + '-deployment';

local postgres_name = name + '-postgres';
local postgres_pvc_name = postgres_name + '-pvc';
local postgres_service_name = postgres_name;

local redis_name = name + '-redis';
local redis_service_name = redis_name;

// Store full Misskey config as a Secret to avoid leaking credentials in ConfigMap
local postgres_secret_name = postgres_name + '-secret';
local misskey_config_secret_name = name + '-config';

// ExternalSecret: fetch DB credentials from 1Password and create Secret for Postgres env
local postgres_ex_secret = {
  apiVersion: 'external-secrets.io/v1',
  kind: 'ExternalSecret',
  metadata: {
    name: postgres_name + '-ex-secret',
    namespace: namespace,
  },
  spec: {
    secretStoreRef: {
      kind: 'ClusterSecretStore',
      name: secret_store_name,
    },
    target: {
      name: postgres_secret_name,
      creationPolicy: 'Owner',
    },
    data: [
      // REPLACE the `key` with your 1Password item id
      { secretKey: 'POSTGRES_USER', remoteRef: { key: 'REPLACE_1PASSWORD_ITEM_ID/username' } },
      { secretKey: 'POSTGRES_PASSWORD', remoteRef: { key: 'REPLACE_1PASSWORD_ITEM_ID/password' } },
    ],
  },
};

// ExternalSecret: render Misskey default.yml as Secret using fetched DB credentials
local misskey_config_ex_secret = {
  apiVersion: 'external-secrets.io/v1',
  kind: 'ExternalSecret',
  metadata: {
    name: name + '-config-ex-secret',
    namespace: namespace,
  },
  spec: {
    secretStoreRef: {
      kind: 'ClusterSecretStore',
      name: secret_store_name,
    },
    target: {
      name: misskey_config_secret_name,
      creationPolicy: 'Owner',
      template: {
        type: 'Opaque',
        data: {
          // Use Go template refs to inject secrets into YAML
          'default.yml': std.join('\n', [
            'url: https://' + public_domain,
            'port: 3000',
            'db:',
            '  host: ' + postgres_service_name,
            '  port: 5432',
            '  db: misskey',
            '  user: {{ .POSTGRES_USER }}',
            '  pass: {{ .POSTGRES_PASSWORD }}',
            'redis:',
            '  host: ' + redis_service_name,
            '  port: 6379',
          ]),
        },
      },
    },
    data: [
      // Same 1Password item as postgres_ex_secret
      { secretKey: 'POSTGRES_USER', remoteRef: { key: 'REPLACE_1PASSWORD_ITEM_ID/username' } },
      { secretKey: 'POSTGRES_PASSWORD', remoteRef: { key: 'REPLACE_1PASSWORD_ITEM_ID/password' } },
    ],
  },
};

// no-op: postgres Secret will be created by ExternalSecret

local postgres_pvc = lib_hash2 { data: {
  apiVersion: 'v1',
  kind: 'PersistentVolumeClaim',
  metadata: {
    name: postgres_pvc_name,
    namespace: namespace,
  },
  spec: {
    accessModes: [
      'ReadWriteOnce',
    ],
    resources: {
      requests: {
        storage: '20Gi',
      },
    },
    storageClassName: 'longhorn-local',
  },
}}.output;

local misskey_files_pvc = lib_hash2 { data: {
  apiVersion: 'v1',
  kind: 'PersistentVolumeClaim',
  metadata: {
    name: name + '-files',
    namespace: namespace,
  },
  spec: {
    accessModes: [
      'ReadWriteOnce',
    ],
    resources: {
      requests: {
        storage: '20Gi',
      },
    },
    storageClassName: 'longhorn-local',
  },
}}.output;

local postgres_deployment = {
  apiVersion: 'apps/v1',
  kind: 'Deployment',
  metadata: {
    name: postgres_name,
    namespace: namespace,
  },
  spec: {
    replicas: 1,
    selector: { matchLabels: { app: postgres_name } },
    template: {
      metadata: {
        labels: { app: postgres_name },
      },
      spec: {
        containers: [
          {
            name: 'postgres',
            image: postgres_image,
            ports: [ { containerPort: 5432 } ],
            envFrom: [ { secretRef: { name: postgres_secret_name } } ],
            volumeMounts: [
              { name: 'data', mountPath: '/var/lib/postgresql/data' },
            ],
          }
        ],
        volumes: [
          { name: 'data', persistentVolumeClaim: { claimName: postgres_pvc.metadata.name } },
        ],
      },
    },
  },
};

local postgres_service = {
  apiVersion: 'v1',
  kind: 'Service',
  metadata: {
    name: postgres_service_name,
    namespace: namespace,
  },
  spec: {
    ports: [ { port: 5432 } ],
    selector: { app: postgres_name },
  },
};

local redis_deployment = {
  apiVersion: 'apps/v1',
  kind: 'Deployment',
  metadata: {
    name: redis_name,
    namespace: namespace,
  },
  spec: {
    replicas: 1,
    selector: { matchLabels: { app: redis_name } },
    template: {
      metadata: { labels: { app: redis_name } },
      spec: {
        containers: [
          {
            name: 'redis',
            image: redis_image,
            ports: [ { containerPort: 6379 } ],
          }
        ],
      },
    },
  },
};

local redis_service = {
  apiVersion: 'v1',
  kind: 'Service',
  metadata: {
    name: redis_service_name,
    namespace: namespace,
  },
  spec: {
    ports: [ { port: 6379 } ],
    selector: { app: redis_name },
  },
};

local misskey_deployment = {
  apiVersion: 'apps/v1',
  kind: 'Deployment',
  metadata: {
    name: misskey_deployment_name,
    namespace: namespace,
  },
  spec: {
    replicas: 1,
    selector: { matchLabels: { app: pod_name } },
    template: {
      metadata: {
        labels: { app: pod_name, 'app.kubernetes.io/name': pod_name },
      },
      spec: {
        containers: [
          {
            name: misskey_container_name,
            image: misskey_image,
            imagePullPolicy: 'IfNotPresent',
            ports: [ { containerPort: 3000 } ],
            env: [
              { name: 'NODE_ENV', value: 'production' },
              { name: 'POSTGRES_PASSWORD', valueFrom: { secretKeyRef: { name: postgres_secret_name, key: 'POSTGRES_PASSWORD' } } },
            ],
            volumeMounts: [
              { name: 'config', mountPath: '/misskey/.config' },
              { name: 'files', mountPath: '/misskey/files' },
            ],
          }
        ],
        volumes: [
          { name: 'config', secret: { secretName: misskey_config_secret_name } },
          { name: 'files', persistentVolumeClaim: { claimName: misskey_files_pvc.metadata.name } },
        ],
      },
    },
  },
};

local misskey_service = {
  apiVersion: 'v1',
  kind: 'Service',
  metadata: {
    name: misskey_service_name,
    namespace: namespace,
  },
  spec: {
    selector: { 'app.kubernetes.io/name': pod_name },
    ports: [ { port: 80, protocol: 'TCP', targetPort: 3000 } ],
  },
};

local misskey_ingress = {
  apiVersion: 'networking.k8s.io/v1',
  kind: 'Ingress',
  metadata: {
    name: misskey_ingress_name,
    namespace: namespace,
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
              backend: { service: { name: misskey_service_name, port: { number: 80 } } },
            }
          ],
        },
      }
    ],
    tls: [ { hosts: [ public_domain ], secretName: public_domain + '-tls' } ],
  },
};

[
  postgres_ex_secret,
  misskey_config_ex_secret,
  postgres_pvc,
  misskey_files_pvc,
  postgres_deployment,
  postgres_service,
  redis_deployment,
  redis_service,
  misskey_deployment,
  misskey_service,
  misskey_ingress,
]

