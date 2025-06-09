local name = (import 'config.json5').name;
local namespace = (import 'config.json5').namespace;

local app_name = name + '-helm';
local app_namespace = 'argocd';

local op_item = {
  apiVersion: 'onepassword.com/v1',
  kind: 'OnePasswordItem',
  metadata: {
    name: name,
  },
  spec: {
    // https://start.1password.com/open/i?a=UWWKBI7TBZCR7JIGGPATTRJZPQ&v=tsa4qdut6lvgsrl5xvsvdnmgwe&i=tibvxjoy34cu3sc5vhfri6cf2u&h=my.1password.com
    itemPath: 'vaults/tsa4qdut6lvgsrl5xvsvdnmgwe/items/tibvxjoy34cu3sc5vhfri6cf2u',
  },
};

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
      // https://artifacthub.io/packages/helm/grafana/grafana
      repoURL: 'https://grafana.github.io/helm-charts',
      chart: 'grafana',
      targetRevision: '9.2.2',
      helm: {
        releaseName: name,
        valuesObject: {
          persistence: {
            type: 'pvc',
            enabled: true,
          },
          admin: {
            existingSecret: op_item.metadata.name,
            userKey: 'username',
            passwordKey: 'password',
          },
          service: {
            enabled: true,
            type: 'ClusterIP',
          },
          datasources: {
            'datasources.yaml': {
              apiVersion: 1,
              datasources: [
                {
                  name: 'Loki',
                  type: 'loki',
                  access: 'proxy',
                  orgId: 1,
                  url: 'http://loki-gateway.' + (import '../grafana-loki/config.json5').namespace + '.svc.cluster.local:80',
                  basicAuth: false,
                  isDefault: false,
                  version: 1,
                  editable: false,
                },
              ],
            },
          },
        },
      },
    },
  },
};

[
  op_item,
  helm_app,
]
