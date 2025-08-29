local name = (import 'config.json5').name;
local namespace = (import 'config.json5').namespace;

local app_name = name + '-helm';
local app_namespace = 'argocd';

local target_namespaces = [
  'argocd',
  (import '../sandbox-http-server-go1/config.json5').namespace,
  (import '../sandbox-http-server-go2/config.json5').namespace,
  (import '../echo-slack-bot-rs/config.json5').namespace,
];

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
      targetRevision: '3.2.7',
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
                local n = (import '../grafana-loki/config.json5').name + '-gateway';
                local ns = (import '../grafana-loki/config.json5').namespace;
                'http://' + n + '.' + ns + '.svc.cluster.local/loki/api/v1/push'
              ),
            },
          ],
          clusterEvents: {
            enabled: true,
            collector: 'alloy-logs',
            namespaces: target_namespaces,
          },
          nodeLogs: {
            enabled: false,
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
            enabled: false,
          },
          'alloy-logs': {
            enabled: true,
            // Required when using the Kubernetes API to pod logs
            alloy: {
              clustering: {
                enabled: true,
              },
              mounts: {
                varlog: false,
                dockercontainers: false,
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
