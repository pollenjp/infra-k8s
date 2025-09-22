local env = (import '../env.jsonnet');

{
  apiVersion: "argoproj.io/v1alpha1",
  kind: "ApplicationSet",
  metadata: {
    name: "default-application-set",
    namespace: "argocd",
  },
  spec: {
    goTemplate: true,
    goTemplateOptions: ["missingkey=error"],
    generators: [
      {
        git: {
          repoURL: "https://github.com/pollenjp/infra-k8s.git",
          revision: "HEAD",
          files: [
            {
              path: env.name + "/apps/*/_app_config.json",
            },
          ],
        },
      },
    ],
    template: {
      metadata: {
        name: "{{.name}}",
      },
      spec: {
        project: "default",
        destination: {
          server: "https://kubernetes.default.svc",
          namespace: "{{.namespace}}",
        },
        source: {
          repoURL: "https://github.com/pollenjp/infra-k8s.git",
          targetRevision: "HEAD",
          path: "{{.path.path}}",
          directory: {
            recurse: true,
            exclude: "{_*/*,_*.json,_*.jsonnet}",
          },
        },
        syncPolicy: {
          automated: {
            selfHeal: true,
            prune: true,
          },
          syncOptions: [
            "CreateNamespace=true",
            "FailOnSharedResource=true",
            "ServerSideApply=true",
          ],
        },
      },
    },
  },
}
