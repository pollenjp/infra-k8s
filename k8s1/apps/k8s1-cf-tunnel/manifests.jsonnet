# NOTE: same as the tunnel name configured in cloudflare
local tunnel_name = 'k8s1-cf-tunnel';
local cf_tunnel_token_name = 'cf-tunnel-token';
local name = (import '_app_config.json').name;
local env = (import '../../env.jsonnet');
local lib_hash2 = (import '../../../jsonnetlib/hash2.libsonnet');

local configMap = lib_hash2 { data: {
  apiVersion: 'v1',
  kind: 'ConfigMap',
  metadata: {
    name: name + '-config',
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
            hostname: 'grafana.pollenjp.com',
            service: (
              local n = (import '../grafana-grafana/_app_config.json').name;
              local ns = (import '../grafana-grafana/_app_config.json').namespace;
              'http://' + n + '.' + ns + '.svc.cluster.local'
            ),
          },
          {
            hostname: 'minio-console.pollenjp.com',
            service: (
              local n = (import '../grafana-loki/_app_config.json').name + '-minio-console';
              local ns = (import '../grafana-loki/_app_config.json').namespace;
              'http://' + n + '.' + ns + '.svc.cluster.local:9001'
            ),
          },
          {
            hostname: 'minio-tenant-1-console.pollenjp.com',
            service: (
              local tenant_name = (import '../minio-tenant-1/_app_config.json').name;
              local n = tenant_name + '-console';
              local ns = (import '../minio-tenant-1/_app_config.json').namespace;
              'http://' + n + '.' + ns + '.svc.cluster.local:9090'
            ),
          },
          {
            hostname: 'authentik.pollenjp.com',
            service: (
              local svc_name = (import '../authentik/_config.jsonnet').export_svc_name;
              local port_num = (import '../authentik/_config.jsonnet').export_svc_port;
              local ns = (import '../authentik/_config.jsonnet').namespace;
              'http://' + svc_name + '.' + ns + '.svc.cluster.local:' + port_num
            ),
          },
          {
            hostname: 'longhorn.pollenjp.com',
            service: 'http://longhorn-frontend.' + (import '../longhorn/_app_config.json').namespace + '.svc.cluster.local',
          },
          (
            local n = 'cilium-ingress-' + (import '../sandbox-http-server-go1/_app_config.json').name;
            local ns = (import '../sandbox-http-server-go1/_app_config.json').namespace;
            {
              hostname: 'sandbox-http-server-go1.pollenjp.com',
              service: 'http://' + n + '.' + ns + '.svc.cluster.local',
            }
          ),
          {
            hostname: 'sandbox-http-server-go2.pollenjp.com',
            service: 'http://sandbox-http-server-go2-svc.' + (import '../sandbox-http-server-go2/_app_config.json').namespace + '.svc.cluster.local:8080',
          },
          {
            hostname: 'sandbox-nginx.pollenjp.com',
            service: (
              // svc
              local n = (import '../sandbox-nginx/_app_config.json').name;
              local ns = (import '../sandbox-nginx/_app_config.json').namespace;
              'http://' + n + '.' + ns + '.svc.cluster.local:8080'
            ),
          },
          (
            local public_domain = (import '../sandbox-nginx/_app_config.json').public_domain;
            {
              hostname: public_domain,
              service: (
                local n = (import '../sandbox-nginx/_app_config.json').name;
                local ns = (import '../sandbox-nginx/_app_config.json').namespace;
                'http://' + n + '.' + ns + '.svc.cluster.local:8080'
              )
            }
          ),
          {
            service: 'http_status:404',
          },
        ],
      },
    ),
  },
} }.output;

local ex_secret_credential_key_name = 'credentials';
local ex_secret = lib_hash2 { data: {
  apiVersion: 'external-secrets.io/v1',
  kind: 'ExternalSecret',
  metadata: {
    name: (import '_app_config.json').name + '-ex-secret',
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
        secretKey: ex_secret_credential_key_name,
        remoteRef: {
          // k8s1-cf-tunnel
          // https://start.1password.com/open/i?a=UWWKBI7TBZCR7JIGGPATTRJZPQ&v=tsa4qdut6lvgsrl5xvsvdnmgwe&i=zvyy23tjbsvgg2jrfpdztsx3zi&h=my.1password.com
          key: 'zvyy23tjbsvgg2jrfpdztsx3zi/yd5tpo6nyf7u76b4tkfwxjpmhi/azt3qsnm3yadx7pbhkhqzx7tfa',
        },
      },
    ]
  },
} }.output;

local deployment = {
  apiVersion: 'apps/v1',
  kind: 'Deployment',
  metadata: {
    name: 'cloudflared',
    labels: {
      'app.kubernetes.io/name': 'k8s1-cf-tunnel',
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
            image: 'mirror.gcr.io/cloudflare/cloudflared:2025.8.1',
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
              secretName: ex_secret.metadata.name,
              items: [
                {
                  key: ex_secret_credential_key_name,
                  path: 'credentials.json',
                },
              ],
            },
          },
          {
            name: 'config',
            configMap: {
              name: configMap.metadata.name,
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
  configMap,
  ex_secret,
  deployment,
]
