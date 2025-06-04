# NOTE: same as the tunnel name configured in cloudflare
local tunnel_name = 'k8s1-cf-tunnel';
local cf_tunnel_token_name = 'cf-tunnel-token';
local name = (import 'config.json5').name;
local env = (import '../../env.jsonnet');
local lib_hash = (import '../../jsonnetlib/hash.libsonnet');

local configMap = {
  apiVersion: 'v1',
  kind: 'ConfigMap',
  metadata: {
    name: 'dummy',
    labels: {
      'app.kubernetes.io/name': 'k8s1-cf-tunnel',
    },
  },
  data: {
    'config.yaml': std.manifestYamlDoc(
      {
        tunnel: tunnel_name,
        'credentials-file': '/etc/cloudflared/creds/credentials.json',
        metrics: '0.0.0.0:2000',
        'no-autoupdate': true,
        ingress: [
          {
            hostname: 'argocd.pollenjp.com',
            service: 'http://argo-argocd-server.argocd.svc.cluster.local',
          },
          {
            hostname: 'sandbox-http-server-go1.pollenjp.com',
            service: 'http://cilium-ingress-sandbox-server-ingress.sandbox-http-server-go1.svc.cluster.local',
          },
          {
            hostname: 'sandbox-http-server-go2.pollenjp.com',
            service: 'http://sandbox-http-server-go2-svc.sandbox-http-server-go2.svc.cluster.local:8080',
          },
          {
            hostname: 'sandbox-nginx.pollenjp.com',
            service: 'http://sandbox-nginx-svc.sandbox-nginx.svc.cluster.local:8080',
          },
          {
            service: 'http_status:404',
          },
        ],
      },
    ),
  },
};
local config_map_name = name + '-' + lib_hash { data: configMap }.output;

local deployment = {
  apiVersion: 'apps/v1',
  kind: 'Deployment',
  metadata: {
    name: 'cloudflared',
    labels: {
      'app.kubernetes.io/name': 'k8s1-cf-tunnel',
    },
    annotations: {
      // https://start.1password.com/open/i?a=UWWKBI7TBZCR7JIGGPATTRJZPQ&v=tsa4qdut6lvgsrl5xvsvdnmgwe&i=zvyy23tjbsvgg2jrfpdztsx3zi&h=my.1password.com
      'operator.1password.io/item-path': 'vaults/tsa4qdut6lvgsrl5xvsvdnmgwe/items/zvyy23tjbsvgg2jrfpdztsx3zi',
      'operator.1password.io/item-name': cf_tunnel_token_name,
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
          'app.kubernetes.io/name': 'k8s1-cf-tunnel',
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
        securityContext: {
          sysctls: [
            {
              name: 'net.ipv4.ping_group_range',
              value: '65532 65532',
            },
          ],
        },
        containers: [
          {
            name: 'cloudflared',
            image: 'mirror.gcr.io/cloudflare/cloudflared:2025.5.0',
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
              secretName: cf_tunnel_token_name,
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
              name: config_map_name,
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

[
  std.mergePatch(configMap, { metadata: { name: config_map_name } }),
  deployment,
]
