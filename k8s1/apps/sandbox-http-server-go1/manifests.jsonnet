local svc_name = (import 'config.json5').name + '-svc';
local pod_name = (import 'config.json5').name + '-pod';
local container_name = (import 'config.json5').name + '-container';
local secret_name = (import 'config.json5').name + '-secret';
local ingress_name = (import 'config.json5').name;

local ex_secret = {
  apiVersion: 'external-secrets.io/v1',
  kind: 'ExternalSecret',
  metadata: {
    name: (import 'config.json5').name + '-ex-secret',
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
      {
        secretKey: 'custom-key',
        remoteRef: {
          # https://start.1password.com/open/i?a=UWWKBI7TBZCR7JIGGPATTRJZPQ&v=tsa4qdut6lvgsrl5xvsvdnmgwe&i=7l622oxh7m6bi2p73grw35ct3y&h=my.1password.com
          key: '7l622oxh7m6bi2p73grw35ct3y/password',
        },
      }
    ]
  },
};

local deployment = {
  apiVersion: 'apps/v1',
  kind: 'Deployment',
  metadata: {
    name: (import 'config.json5').name,
    labels: {
      'app.kubernetes.io/name': (import 'config.json5').name,
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
                    name: ex_secret.metadata.name,
                    key: 'custom-key',
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
    name: svc_name,
    labels: {
      'app.kubernetes.io/name': svc_name,
    },
  },
  spec: {
    selector: {
      'app.kubernetes.io/name': pod_name,
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

local ingress = {
  apiVersion: 'networking.k8s.io/v1',
  kind: 'Ingress',
  metadata: {
    name: ingress_name,
    labels: {
      'app.kubernetes.io/name': ingress_name,
    },
    annotations: {
      'description': 'cilium-ingress\' example',
      'ingress.cilium.io/loadbalancer-mode': 'dedicated',
    },
  },
  spec: {
    ingressClassName: 'cilium',
    rules: [
      {
        host: 'sandbox-http-server-go1.pollenjp.com',
        http: {
          paths: [
            {
              path: '/',
              pathType: 'Prefix',
              backend: {
                service: {
                  name: svc_name,
                  port: {
                    number: 8080,
                  },
                },
              },
            },
          ]
        }
      }
    ],
  },
};

[
  ex_secret,
  deployment,
  service,
  ingress,
]
