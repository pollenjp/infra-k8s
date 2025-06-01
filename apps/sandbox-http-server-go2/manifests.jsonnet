local deployment = {
  apiVersion: 'apps/v1',
  kind: 'Deployment',
  metadata: {
    name: (import 'config.json5').name,
    labels: {
      'app.kubernetes.io/name': (import 'config.json5').name,
    },
    annotations: {
      'operator.1password.io/item-path': 'vaults/tsa4qdut6lvgsrl5xvsvdnmgwe/items/7l622oxh7m6bi2p73grw35ct3y',
      'operator.1password.io/item-name': (import 'config.json5').name + '-secret',
    },
  },
  spec: {
    replicas: 3,
    selector: {
      matchLabels: {
        'app.kubernetes.io/name': (import 'config.json5').name + '-pod',
      },
    },
    template: {
      metadata: {
        labels: {
          'app.kubernetes.io/name': (import 'config.json5').name + '-pod',
        },
      },
      spec: {
        containers: [
          {
            name: (import 'config.json5').name + '-container',
            image: 'ghcr.io/pollenjp/sandbox-http-server-go:0.1.17',
            imagePullPolicy: 'Always',
            ports: [
              {
                containerPort: 8080,
              },
            ],
            env: [
              {
                name: 'SERVER_PORT',
                value: '8080',
              },
              {
                name: 'SAMPLE_VAR',
                valueFrom: {
                  secretKeyRef: {
                    name: (import 'config.json5').name + '-secret',
                    key: 'username',
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

local service = {
  apiVersion: 'v1',
  kind: 'Service',
  metadata: {
    name: (import 'config.json5').name + '-svc',
    labels: {
      'app.kubernetes.io/name': (import 'config.json5').name + '-svc',
    },
  },
  spec: {
    selector: {
      'app.kubernetes.io/name': (import 'config.json5').name + '-pod',
    },
    ports: [
      {
        port: 8080,
        protocol: 'TCP',
        targetPort: 8080,
      },
    ],
  },
};

[deployment, service]
