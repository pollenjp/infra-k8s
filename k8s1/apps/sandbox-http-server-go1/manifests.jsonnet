local name = (import '_app_config.json').name;
local svc_name = name + '-svc';
local pod_name = name + '-pod';
local container_name = name + '-container';
local secret_name = name + '-secret';
local ingress_name = name;
local lib_hash2 = import '../../../jsonnetlib/hash2.libsonnet';


local ex_secret = lib_hash2 { data: {
  apiVersion: 'external-secrets.io/v1',
  kind: 'ExternalSecret',
  metadata: {
    name: secret_name,
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
          # password
          key: '7l622oxh7m6bi2p73grw35ct3y/ho4o6bkehsvs5atdzzhbd37etq',
        },
      }
    ]
  },
} }.output;

local deployment = {
  apiVersion: 'apps/v1',
  kind: 'Deployment',
  metadata: {
    name: (import '_app_config.json').name,
    labels: {
      'app.kubernetes.io/name': (import '_app_config.json').name,
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
            image: 'ghcr.io/pollenjp/sandbox-http-server-go:0.2.0',
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
