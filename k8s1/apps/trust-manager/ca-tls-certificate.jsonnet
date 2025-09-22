local lib_hash2 = (import '../../../jsonnetlib/hash2.libsonnet');

local name = (import '_app_config.json').name;
local namespace = (import '_app_config.json').namespace;

// https://docs.min.io/community/minio-object-store/operations/cert-manager/cert-manager-operator.html
local certificate = lib_hash2 { data: {
  apiVersion: 'cert-manager.io/v1',
  kind: 'Certificate',
  metadata: {
    name: name,
    namespace: namespace,
  },
  spec: {
    isCA: true,
    commonName: name,
    secretName: '', // embed later
    duration: '70128h', // 8y
    privateKey: {
      algorithm: 'ECDSA',
      size: 256,
    },
    issuerRef: (
      local root_clusterissuer = (import 'selfsigned-root-clusterissuer.jsonnet');
      {
        name: root_clusterissuer.metadata.name,
        kind: root_clusterissuer.kind,
        group: std.splitLimit(root_clusterissuer.apiVersion, '/', 1)[0],
      }
    ),
  },
} }.output;


std.mergePatch(certificate, {
  metadata: { name: certificate.metadata.name + '-ca-certificate' },
  spec: {
    secretName: certificate.metadata.name + '-ca-tls',
  },
})
