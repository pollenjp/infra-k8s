local lib_hash2 = import '../../../jsonnetlib/hash2.libsonnet';

local config = (import '_config.jsonnet');

lib_hash2 { data: {
  apiVersion: 'external-secrets.io/v1',
  kind: 'ExternalSecret',
  metadata: {
    name: (import '_app_config.json').name + '-ex-secret',
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
      {
        secretKey: secret.key_name,
        remoteRef: {
          key: secret.onepassword_key,
        },
      } for secret in std.objectValues(config.secrets)
    ]
  },
} }.output
