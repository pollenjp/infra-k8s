local lib_hash2 = (import '../../../jsonnetlib/hash2.libsonnet');

local name = (import '_app_config.json').name;
local namespace = (import '_app_config.json').namespace;

// https://docs.min.io/community/minio-object-store/operations/cert-manager/cert-manager-operator.html
//
// it is easy to use trust-manager for delivery of the certificate
local certificate = lib_hash2 { data: {
  apiVersion: 'cert-manager.io/v1',
  kind: 'Certificate',
  metadata: {
    name: name,
    namespace: namespace,
  },
  spec: {
    dnsNames:[
       "minio." + namespace + "",
       "minio." + namespace + ".svc",
       'minio.' + namespace + '.svc.cluster.local',
       '*.minio.' + namespace + '.svc.cluster.local',
       '*.' + name + '-hl.' + namespace + '.svc.cluster.local',
       '*.' + name + '.minio.' + namespace + '.svc.cluster.local',
    ],
    secretName: '', // embed later for hash
    issuerRef: {
      name: (import '../trust-manager/ca-issuer.jsonnet').metadata.name,
      kind: 'ClusterIssuer',
    },
  },
} }.output;

std.mergePatch(certificate, {
  metadata: { name: certificate.metadata.name + '-sts-cert' },
  spec: {
    secretName: certificate.metadata.name + '-sts-tls',
  },
})
