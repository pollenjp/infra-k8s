local tunnel_name = 'k8s1-cf-tunnel';

local deployment = {
  apiVersion: 'apps/v1',
  kind: 'Deployment',
  metadata: {
    name: 'cloudflared',
    annotations: {
      'operator.1password.io/item-path': 'vaults/tsa4qdut6lvgsrl5xvsvdnmgwe/items/zvyy23tjbsvgg2jrfpdztsx3zi',
      'operator.1password.io/item-name': 'cf-tunnel-token',
    },
  },
  spec: {
    selector: {
      matchLabels: {
        app: 'cloudflared',
      },
    },
    replicas: 2,
    strategy: {
      type: 'RollingUpdate',
      rollingUpdate: {
        maxUnavailable: 1,
        maxSurge: 0,
      },
    },
    template: {
      metadata: {
        labels: {
          app: 'cloudflared',
        },
      },
      spec: {
        affinity: {
          podAntiAffinity: {
            requiredDuringSchedulingIgnoredDuringExecution: [
              {
                labelSelector: {
                  matchLabels: {
                    app: 'cloudflared',
                  },
                },
                topologyKey: 'kubernetes.io/hostname',
              },
            ],
          },
        },
        containers: [
          {
            name: 'cloudflared',
            image: 'mirror.gcr.io/cloudflare/cloudflared:2025.5.0',
            securityContext: {
              sysctls: [
                {
                  name: 'net.ipv4.ping_group_range',
                  value: '65532 65532',
                },
              ],
            },
            args: [
              'tunnel',
              '--config',
              '/etc/cloudflared/config/config.yaml',
              'run',
            ],
            livenessProbe: {
              httpGet: {
                path: '/ready',
                port: 2000,
              },
              failureThreshold: 20,
              initialDelaySeconds: 5,
              periodSeconds: 10,
            },
            readinessProbe: {
              httpGet: {
                path: '/ready',
                port: 2000,
              },
              successThreshold: 10,
              initialDelaySeconds: 5,
              periodSeconds: 10,
            },
            volumeMounts: [
              {
                name: 'config',
                mountPath: '/etc/cloudflared/config',
                readOnly: true,
              },
              {
                name: 'creds',
                mountPath: '/etc/cloudflared/creds',
                readOnly: true,
              },
            ],
          },
        ],
        volumes: [
          {
            name: 'creds',
            secret: {
              secretName: 'cf-tunnel-token',
              items: [
                {
                  key: 'password',
                  path: 'credentials.json',
                },
              ],
            },
          },
          {
            name: 'config',
            configMap: {
              name: 'cloudflared',
              items: [
                {
                  key: 'config.yaml',
                  path: 'config.yaml',
                },
              ],
            },
          },
        ],
      },
    },
  },
};

local configMap = {
  apiVersion: 'v1',
  kind: 'ConfigMap',
  metadata: {
    name: 'cloudflared',
  },
  data: {
    'config.yaml': |||
      tunnel: %(tunnel_name)s
      credentials-file: /etc/cloudflared/creds/credentials.json

      # Serves the metrics server under /metrics and the readiness server under /ready
      metrics: 0.0.0.0:2000

      # autoupdate doesn't make sense in Kubernetes
      no-autoupdate: true

      ingress:
        - hostname: argocd.pollenjp.com
          service: http://argo-argocd-server.argocd.svc.cluster.local
        - hostname: sandbox-http-server-go.pollenjp.com
          service: http://cilium-ingress-sandbox-http-server-go-sample-ingress.sandbox-http-server-go-sample.svc.cluster.local
        - hostname: www.pollenjp.com
          service: http://sandbox-http-server-go-sample-svc.sandbox-http-server-go-sample.svc.cluster.local:8080
        - service: http_status:404
    |||,
  },
};

[
  deployment,
  configMap,
]
