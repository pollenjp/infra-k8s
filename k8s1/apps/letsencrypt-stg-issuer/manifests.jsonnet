local lib_hash = (import '../../../jsonnetlib/hash.libsonnet');

local name = (import 'config.json5').name;

local op_item = {
  apiVersion: 'onepassword.com/v1',
  kind: 'OnePasswordItem',
  metadata: {
    name: 'dummy',
    namespace: (import '../cert-manager/config.json5').namespace, // NOTE: need to be the same
  },
  spec: {
    // https://start.1password.com/open/i?a=UWWKBI7TBZCR7JIGGPATTRJZPQ&v=tsa4qdut6lvgsrl5xvsvdnmgwe&i=zorjm5yua3fhmgsk5morbt5edi&h=my.1password.com
    itemPath: 'vaults/tsa4qdut6lvgsrl5xvsvdnmgwe/items/zorjm5yua3fhmgsk5morbt5edi',
  },
};
local op_item_name = name + '-' + lib_hash {data: op_item}.output;

local cluster_issuer = {
  apiVersion: 'cert-manager.io/v1',
  kind: 'ClusterIssuer',
  metadata: {
    name: name,
  },
  spec: {
    // https://cert-manager.io/docs/tutorials/acme/pomerium-ingress/#configure-lets-encrypt-issuer
    acme: {
      // https://letsencrypt.org/docs/staging-environment/
      server: 'https://acme-staging-v02.api.letsencrypt.org/directory',
      // The email field is required by Let's Encrypt and used to notify you of certificate expiration and updates.
      email: 'polleninjp+letsencrypt@gmail.com',
      privateKeySecretRef: {
        name: name,
      },
      solvers: [
        {
          dns01: {
            // https://cert-manager.io/docs/configuration/acme/dns01/cloudflare/
            cloudflare: {
              apiTokenSecretRef: {
                name: op_item_name,
                key: 'password',
              }
            }
          }
        }
      ]
    },
  },
};

[
  std.mergePatch(op_item, { metadata: { name: op_item_name } }),
  cluster_issuer,
]
