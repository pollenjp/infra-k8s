{
  apiVersion: 'argoproj.io/v1alpha1',
  kind: 'Application',
  metadata: {
    name: (import 'config.json5').name,
    namespace: (import 'config.json5').namespace,
  },
  spec: {
    project: 'default',
    destination: {
      server: 'https://kubernetes.default.svc',
      namespace: (import 'config.json5').release_namespace,
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
      repoURL: (import 'config.json5').chart_repo_url,
      chart: (import 'config.json5').release_chart,
      targetRevision: (import 'config.json5').chart_version,
      helm: {
        releaseName: (import 'config.json5').release_name,
        values: (importstr 'values.yaml'),
      },
    },
  },
}
