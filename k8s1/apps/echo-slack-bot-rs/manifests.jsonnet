local lib_hash2 = import '../../../jsonnetlib/hash2.libsonnet';

local name = (import '_app_config.json').name;
local pod_name = name + '-pod';
local container_name = name + '-container';

local ex_secret = lib_hash2 { data: {
  apiVersion: 'external-secrets.io/v1',
  kind: 'ExternalSecret',
  metadata: {
    name: name + '-ex-secret',
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
      // https://start.1password.com/open/i?a=UWWKBI7TBZCR7JIGGPATTRJZPQ&v=tsa4qdut6lvgsrl5xvsvdnmgwe&i=csuocfytgsdfzticoha46vunmu&h=my.1password.com
      {
        secretKey: 'SLACK_APP_LEVEL_TOKEN',
        remoteRef: {
          key: 'csuocfytgsdfzticoha46vunmu/rfpgyjc27hlgrxf5rbqdwp7ixm/hvwqfdb4acmptpn52qgl5nhwde',
        },
      },
      {
        secretKey: 'SLACK_USER_OAUTH_TOKEN',
        remoteRef: {
          key: 'csuocfytgsdfzticoha46vunmu/rfpgyjc27hlgrxf5rbqdwp7ixm/nuku4shdxskjrjkwzjtwnbztsy',
        },
      },
    ]
  },
} }.output;


local deployment = {
  apiVersion: 'apps/v1',
  kind: 'Deployment',
  metadata: {
    name: name,
    labels: {
      'app.kubernetes.io/name': name,
    },
  },
  spec: {
    replicas: 1,
    selector: {
      matchLabels: {
        'app.kubernetes.io/name': pod_name,
      },
    },
    template: {
      metadata: {
        labels: {
          'app.kubernetes.io/name': pod_name,
        },
      },
      spec: {
        containers: [
          {
            name: container_name,
            image: 'ghcr.io/pollenjp/echo-slack-bot-rs:0.2.0',
            imagePullPolicy: 'Always',
            env: [
              {
                name: 'SLACK_APP_LEVEL_TOKEN',
                valueFrom: {
                  secretKeyRef: {
                    name: ex_secret.metadata.name,
                    key: 'SLACK_APP_LEVEL_TOKEN',
                  },
                },
              },
              {
                name: 'SLACK_USER_OAUTH_TOKEN',
                valueFrom: {
                  secretKeyRef: {
                    name: ex_secret.metadata.name,
                    key: 'SLACK_USER_OAUTH_TOKEN',
                  },
                },
              },
            ],
          },
        ],
      },
    },
  },
};

[
  ex_secret,
  deployment,
]
