local lib_hash2 = (import '../../../jsonnetlib/hash2.libsonnet');

local name = (import 'config.json5').name;
local namespace = (import 'config.json5').namespace;

// https://docs.min.io/community/minio-object-store/operations/cert-manager/cert-manager-operator.html
local certificate = lib_hash2 { data: {
  apiVersion: 'cert-manager.io/v1',
  kind: 'Certificate',
  metadata: {
    name: name + '-sts-cert',
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
    secretName: name + '-sts-tls',
    issuerRef: {
      name: (import 'ca-issuer.jsonnet').metadata.name,
    },
  },
} }.output;

certificate
