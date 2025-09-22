local name = (import '_app_config.json').name;
local namespace = (import '_app_config.json').namespace;

{
  apiVersion: 'trust.cert-manager.io/v1alpha1',
  kind: 'Bundle',
  metadata: {
    // 'operator-ca-tls-' prefix is required -> automatically read by minio-operator
    // https://docs.min.io/community/minio-object-store/operations/cert-manager/cert-manager-tenants.html#trust-the-tenant-s-ca-in-minio-operator
    //
    // same ca is used in operator and tenant
    name: 'operator-ca-tls-' + 'minio-common-ca-tls',
    namespace: namespace,
  },
  spec: {
    sources: [
      {
        useDefaultCAs: true,
      },
      {
        secret: {
          name: (import 'ca-tls-certificate.jsonnet').spec.secretName,
          key: 'ca.crt',
        },
      },
    ],
    target: {
      secret: {
        key: 'ca.crt',
      },
      namespaceSelector: {
        matchLabels: {
          'kubernetes.io/metadata.name': (import '../minio-operator/_app_config.json').namespace,
        },
      },
    },
  },
}
