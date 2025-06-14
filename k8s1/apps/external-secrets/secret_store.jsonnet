local namespace = (import 'config.json5').namespace;

// https://external-secrets.io/latest/provider/1password-sdk/
local op_secret_store = {
  apiVersion: 'external-secrets.io/v1',
  // kind: 'SecretStore',
  kind: 'ClusterSecretStore',
  metadata: {
    name: 'onepassword-sdk',
    namespace: namespace,
  },
  spec: {
    provider: {
      onepasswordSDK: {
        // vault: 'tsa4qdut6lvgsrl5xvsvdnmgwe', # 'k8s1'
        vault: 'k8s1',
        auth: {
          serviceAccountSecretRef: {
            # This 'Secret' resource is created by 'cdk-ansible'
            # https://start.1password.com/open/i?a=UWWKBI7TBZCR7JIGGPATTRJZPQ&v=olaezna7txg3auf65jivo74zbe&i=w7qev4wwbjzpn2a5kfkq7nla3a&h=my.1password.com
            namespace: 'onepassword',
            name: 'k8s1-service-account-auth-token',
            key: 'token',
          },
        },
        // integrationInfo: {
        //   name: 'integration-info',
        //   version: 'v1',
        // },
      },
    },
  },
};

op_secret_store
