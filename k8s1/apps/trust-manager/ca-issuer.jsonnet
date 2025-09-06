local lib_hash2 = (import '../../../jsonnetlib/hash2.libsonnet');

local name = (import 'config.json5').name;

// https://docs.min.io/community/minio-object-store/operations/cert-manager/cert-manager-operator.html
local issuer = lib_hash2 { data: {
  apiVersion: 'cert-manager.io/v1',
  kind: 'ClusterIssuer',
  metadata: {
    name: name + '-issuer',
  },
  spec: {
    ca: {
      secretName: (import 'ca-tls-certificate.jsonnet').spec.secretName,
    },
  },
} }.output;

issuer
