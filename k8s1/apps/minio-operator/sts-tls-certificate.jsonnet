local lib_hash2 = (import '../../../jsonnetlib/hash2.libsonnet');

local name = (import 'config.json5').name;
local namespace = (import 'config.json5').namespace;

// https://docs.min.io/community/minio-object-store/operations/cert-manager/cert-manager-operator.html
# sts-tls-certificate.yaml
// apiVersion: cert-manager.io/v1
// kind: Certificate
// metadata:
//   name: sts-certmanager-cert
//   namespace: minio-operator
// spec:
//   dnsNames:
//     - sts
//     - sts.minio-operator.svc
//     - sts.minio-operator.svc.cluster.local # Replace cluster.local with the value for your domain.
//   secretName: sts-tls
//   issuerRef:
//     name: minio-operator-ca-issuer
local certificate = lib_hash2 { data: {
  apiVersion: 'cert-manager.io/v1',
  kind: 'Certificate',
  metadata: {
    name: name + '-sts-cert',
    namespace: namespace,
  },
  spec: {
    dnsNames:[
      'sts',
      'sts.' + namespace + '.svc',
      'sts.' + namespace + '.svc.cluster.local',
    ],
    // https://docs.min.io/community/minio-object-store/operations/cert-manager/cert-manager-operator.html#id4
    // > The STS service will not start if the sts-tls secret, containing the TLS certificate,
    // > is missing or contains an invalid key-value pair.
    //
    // the name is hard coded in the controller
    // https://github.com/minio/operator/blob/e054c34ee36535b1323337816450dd7b3fcac482/pkg/controller/sts.go#L55-L56
    secretName: 'sts-tls',
    issuerRef: {
      name: (import 'ca-issuer.jsonnet').metadata.name,
    },
  },
} }.output;

certificate
