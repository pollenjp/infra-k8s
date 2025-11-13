local name = (import '_app_config.json').name;
local namespace = (import '_app_config.json').namespace;

local app_name = name + '-helm';
local app_namespace = 'argocd';

local target_namespaces = (
  local including = [
    'argocd',
  ] + std.objectFields((import '_namespaces.autogen.json').namespaces);
  local excluding = [
    namespace, // self
    (import '../grafana-loki/_app_config.json').namespace,
    (import '../grafana-mimir/_app_config.json').namespace,
    (import '../minio-tenant-1/_app_config.json').namespace,
    (import '../cilium-l2-announcement/_app_config.json').namespace,
  ];
  std.filter(
    function(namespace) !std.contains(excluding, namespace),
    including,
  )
);

local helm_app = {
  apiVersion: 'argoproj.io/v1alpha1',
  kind: 'Application',
  metadata: {
    name: app_name,
    namespace: app_namespace,
  },
  spec: {
    project: 'default',
    destination: {
      server: 'https://kubernetes.default.svc',
      namespace: namespace,
    },
    syncPolicy: {
      automated: {
        selfHeal: true,
        prune: true,
      },
      syncOptions: [
        'CreateNamespace=true',
        'ServerSideApply=true',
        'FailOnSharedResource=true',
      ],
    },
    source: {
      // https://grafana.com/docs/loki/latest/send-data/k8s-monitoring-helm/#deploy-the-kubernetes-monitoring-helm-chart
      // https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring
      // https://artifacthub.io/packages/helm/grafana/k8s-monitoring
      repoURL: 'https://grafana.github.io/helm-charts',
      chart: 'k8s-monitoring',
      targetRevision: '3.5.6',
      helm: {
        releaseName: name,
        valuesObject: {
          cluster: {
            name: 'monitoring-sample',
          },
          destinations: [
            {
              name: 'loki',
              type: 'loki',
              url: (
                local n = (import '../grafana-loki/_app_config.json').name + '-gateway';
                local ns = (import '../grafana-loki/_app_config.json').namespace;
                'http://' + n + '.' + ns + '.svc.cluster.local/loki/api/v1/push'
              ),
            },
            {
              name: 'mimir',
              type: 'prometheus',
              url: (
                local n = (import '../grafana-mimir/_config.jsonnet').name + '-gateway';
                local ns = (import '../grafana-mimir/_config.jsonnet').namespace;
                'http://' + n + '.' + ns + '.svc.cluster.local/api/v1/push'
              ),
            },
          ],
          // integrations: {
          //   grafana: {
          //     instances: [
          //       {
          //         name: 'grafana',
          //         labelSelectors: {
          //           // .Chart.Name
          //           // https://github.com/grafana/helm-charts/blob/d73a322972ab1ef4220154199b1e28405b60d53a/charts/grafana/templates/_helpers.tpl#L5-L7
          //           'app.kubernetes.io/name': 'grafana',
          //         },
          //         namespaces: [
          //           (import '../grafana-grafana/_app_config.json').namespace,
          //         ],
          //       }
          //     ]
          //   }
          // },
          clusterEvents: {
            enabled: true,
            collector: 'alloy-logs',
            namespaces: target_namespaces,
          },
          nodeLogs: {
            enabled: true,
          },
          podLogs: {
            enabled: true,
            gatherMethod: 'kubernetesApi',
            collector: 'alloy-logs',
            labelsToKeep: [
              'app_kubernetes_io_name',
              'container',
              'instance',
              'job',
              'level',
              'namespace',
              'service_name',
              'service_namespace',
              'deployment_environment',
              'deployment_environment_name',
            ],
            structuredMetadata: {
              pod: 'pod',
            },
            namespaces: target_namespaces,
          },

          // Collectors
          'alloy-singleton': {
            enabled: false,
          },
          'alloy-metrics': {
            enabled: true,
          },
          'alloy-logs': {
            enabled: true,
            // Required when using the Kubernetes API to pod logs
            alloy: {
              clustering: {
                enabled: true,
              },
              mounts: {
                varlog: true, // for nodeLogs
                dockercontainers: true,
              },
            },
          },
          'alloy-profiles': {
            enabled: false,
          },
          'alloy-receiver': {
            enabled: false,
          },
        },
      },
    },
  },
};

[
  helm_app,
]
