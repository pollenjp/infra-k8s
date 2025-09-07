local lib_hash2 = (import '../../../jsonnetlib/hash2.libsonnet');

local name = (import 'config.json5').name;

// https://docs.min.io/community/minio-object-store/operations/network-encryption/cert-manager.html
local selfsigned_root_clusterissuer = lib_hash2 { data: {
  apiVersion: 'cert-manager.io/v1',
  kind: 'ClusterIssuer',
  metadata: {
    name: name + '-selfsigned-root',
  },
  spec: {
    selfSigned: {},
  },
} }.output;

selfsigned_root_clusterissuer
