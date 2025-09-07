local name = (import 'config.json5').name;
local namespace = (import 'config.json5').namespace;

{
  apiVersion: 'trust.cert-manager.io/v1alpha1',
  kind: 'Bundle',
  metadata: {
    name: name + '-trust-bundle',
    namespace: namespace,
  },
  spec: {
    sources: [
      { useDefaultCAs: true },
      {
        secret: {
          name: (import 'ca-tls-certificate.jsonnet').spec.secretName,
          key: 'tls.crt',
        },
      },
    ],
    target: {
      configMap: {
        key: 'trust-bundle.pem',
      },
    },
  },
}
