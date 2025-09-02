local lib_hash2 = (import '../../../jsonnetlib/hash2.libsonnet');

local name = (import 'config.json5').name;
local namespace = (import 'config.json5').namespace;

local operator_name = (import '../minio-operator/config.json5').name;
local operator_namespace = (import '../minio-operator/config.json5').namespace;

// https://docs.min.io/community/minio-object-store/operations/cert-manager/cert-manager-tenants.html#create-operator-ca-tls-tenant-1-secret

// minio-operator ExternalSecret Operator Service Account
local minio_op_eso_sa = {
  apiVersion: 'v1',
  kind: 'ServiceAccount',
  metadata: {
    name: operator_name + '-eso-sa',
    namespace: operator_namespace,
  },
};
local minio_op_eso_cr = {
  apiVersion: 'rbac.authorization.k8s.io/v1',
  kind: 'ClusterRole',
  metadata: {
    name: operator_name + '-eso-cr',
  },
  rules: [
    {
      apiGroups: [''],
      resources: ['secrets'],
      verbs: ['get', 'list'],
    }
  ]
};
local minio_op_eso_crb = {
  apiVersion: 'rbac.authorization.k8s.io/v1',
  kind: 'ClusterRoleBinding',
  metadata: {
    name: operator_name + '-eso-crb',
  },
  roleRef: {
    apiGroup: 'rbac.authorization.k8s.io',
    kind: 'ClusterRole',
    name: minio_op_eso_cr.metadata.name,
  },
  subjects: [
    {
      kind: 'ServiceAccount',
      name: minio_op_eso_sa.metadata.name,
      namespace: minio_op_eso_sa.metadata.namespace,
    }
  ]
};

local k8s_secret_store = {
  apiVersion: 'external-secrets.io/v1',
  kind: 'SecretStore',
  metadata: {
    name: name + '-k8s-store',
    namespace: operator_namespace,
  },
  spec: {
    provider: {
      kubernetes: { // https://external-secrets.io/main/provider/kubernetes/
        remoteNamespace: namespace,
        // https://external-secrets.io/main/provider/kubernetes/#target-api-server-configuration
        auth: {
          serviceAccount: {
            name: minio_op_eso_sa.metadata.name,
            namespace: minio_op_eso_sa.metadata.namespace,
          },
        },
        server: {
          caProvider: {
            type: 'ConfigMap',
            name: 'kube-root-ca.crt',
            key: 'ca.crt',
          }
        }
      }
    },
  },
};

local operator_ca_tls = lib_hash2 { data: {
  apiVersion: 'external-secrets.io/v1',
  kind: 'ExternalSecret',
  metadata: {
    // 'operator-ca-tls-' prefix is required
    // https://docs.min.io/community/minio-object-store/operations/cert-manager/cert-manager-tenants.html#trust-the-tenant-s-ca-in-minio-operator
    name: 'operator-ca-tls-' + namespace,
    namespace: operator_namespace,
  },
  spec: {
    refreshInterval: '1h',
    secretStoreRef: {
      kind: 'SecretStore',
      name: k8s_secret_store.metadata.name,
    },
    data: [
      {
        secretKey: 'ca.crt',
        remoteRef: {
          key: (import 'ca-tls-certificate.jsonnet').spec.secretName,
          property: 'ca.crt',
        },
      }
    ],
  }
} }.output;


[
  minio_op_eso_sa,
  minio_op_eso_cr,
  minio_op_eso_crb,
  k8s_secret_store,
  operator_ca_tls,
]
