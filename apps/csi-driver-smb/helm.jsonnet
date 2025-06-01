{
  apiVersion: 'argoproj.io/v1alpha1',
  kind: 'Application',
  metadata: {
    name: (import 'config.json5').name + '-helm',
    namespace: 'argocd',
  },
  spec: {
    project: 'default',
    destination: {
      server: 'https://kubernetes.default.svc',
      namespace: (import 'config.json5').namespace,
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
      repoURL: 'https://raw.githubusercontent.com/kubernetes-csi/csi-driver-smb/master/charts',
      chart: (import 'config.json5').name,
      targetRevision: 'v1.18.0',
      helm: {
        releaseName: (import 'config.json5').name,
        values: (importstr 'values.yaml'),
      },
    },
  },
}
