local name = (import 'config.json5').name;
local namespace = (import 'config.json5').namespace;

// create a service account
local service_account = {
  apiVersion: 'v1',
  kind: 'ServiceAccount',
  metadata: {
    name: name + '-sa',
    namespace: namespace,
  },
};

// create a deployment having a busybox pod with the service account
local deployment = {
  apiVersion: 'apps/v1',
  kind: 'Deployment',
  metadata: {
    name: name + '-deployment',
    namespace: namespace,
  },
  spec: {
    replicas: 1,
    selector: {
      matchLabels: {
        app: name,
      },
    },
    template: {
      metadata: {
        labels: {
          app: name,
        },
      },
      spec: {
        serviceAccountName: service_account.metadata.name,
        containers: [
          {
            name: 'busybox',
            image: 'busybox:latest',
            command: [
              'sh',
              '-c',
              'while true; do ls -l /var/run/secrets/kubernetes.io/serviceaccount/token; sleep 30; done',
            ],
          },
        ],
      },
    },
  },
};

// create a policy binding in 'minio-tenant-1'
local policy_binding = {
  apiVersion: 'sts.min.io/v1alpha1',
  kind: 'PolicyBinding',
  metadata: {
    name: name + '-binding',
    namespace: (import '../minio-tenant-1/config.json5').namespace,
  },
  spec: {
    application: {
      namespace: namespace,
      serviceaccount: service_account.metadata.name,
    },
    policies: [
      'readwrite',
    ],
  },
};

[
  service_account,
  deployment,
  policy_binding,
]
