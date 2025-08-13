local lib_hash2 = import '../../../jsonnetlib/hash2.libsonnet';

local name = (import 'config.json5').name;

local db_tier = "database";
local db_postgres_db_name = 'testdb';
local db_svc_name = name + '-db-svc';
local db_pvc_name = name + '-db-pvc';
local db_pod_name = name + '-db-pod';
local db_deployment_name = name + '-db-deployment';
local db_container_name = name + '-db-container';
local db_port = 5432;

local svc_name = name + '-svc';
local pod_name = name + '-pod';
local container_name = name + '-container';


// Database

local db_op_item = lib_hash2 { data: {
  apiVersion: 'onepassword.com/v1',
  kind: 'OnePasswordItem',
  metadata: {
    name: name + '-db-secret',
  },
  spec: {
    // https://start.1password.com/open/i?a=UWWKBI7TBZCR7JIGGPATTRJZPQ&v=tsa4qdut6lvgsrl5xvsvdnmgwe&i=cbzvupr24qufjecn6f5g5ubf2a&h=my.1password.com
    itemPath: 'vaults/tsa4qdut6lvgsrl5xvsvdnmgwe/items/cbzvupr24qufjecn6f5g5ubf2a',
  },
} }.output;

local db_cm = lib_hash2 { data: {
  apiVersion: "v1",
  kind: "ConfigMap",
  metadata: {
    name: name + '-db-cm',
    labels: {
      tier: db_tier,
    }
  },
  data: {
    'initdb.sql': |||
      SET client_encoding = 'UTF8';

      -- DROP TABLE access_log IF EXISTS;

      CREATE TABLE access_log (
        id        serial                 primary key
        ,ip        varchar(21)  not null              -- <ipv4>:<port> (15 + 1 + 5 = 21 )
        ,url_path  varchar(255) not null              -- url path
        ,access_ts timestamp    not null
      );

      -- test data
      INSERT INTO access_log
        (ip, url_path, access_ts)
      VALUES
        ('192.168.10.4', '/', NOW())
      ;
    |||
  }
} }.output;

local db_svc = {
  apiVersion: "v1",
  kind: "Service",
  metadata: {
    name: db_svc_name,
    labels: {
      app: db_svc_name,
      tier: db_tier,
    }
  },
  spec: {
    ports: [
      {
        port: db_port,
      }
    ],
    selector: {
      app: db_pod_name,
      tier: db_tier,
    },
  }
};

local node_affinity = {
  requiredDuringSchedulingIgnoredDuringExecution: {
    nodeSelectorTerms: [
      {
        matchExpressions: [
          {
            key: 'storage.longhorn.pollenjp.com/enabled',
            operator: 'In',
            values: [
              'true'
            ]
          }
        ]
      }
    ]
  }
};

local db_pvc = {
  apiVersion: "v1",
  kind: "PersistentVolumeClaim",
  metadata: {
    name: db_pvc_name,
    labels: {
      app: db_pvc_name,
      tier: db_tier,
    }
  },
  spec: {
    accessModes: ["ReadWriteOnce"],
    resources: {
      requests: {
        storage: "1Gi"
      }
    },
  }
};

local db_deployment = {
  apiVersion: "apps/v1",
  kind: "Deployment",
  metadata: {
    name: db_deployment_name,
    labels: {
      app: db_deployment_name,
      tier: db_tier,
    }
  },
  spec: {
    selector: {
      matchLabels: {
        app: db_pod_name,
        tier: db_tier,
      }
    },
    strategy: {
      type: "Recreate"
    },
    template: {
      metadata: {
        labels: {
          app: db_pod_name,
          tier: db_tier,
        }
      },
      spec: {
        affinity: {
          nodeAffinity: node_affinity,
        },
        containers: [
          {
            name: db_container_name,
            image: "mirror.gcr.io/library/postgres:17.5",
            imagePullPolicy: "Always",
            // resources: {
            //   limits: {
            //     memory: "128Mi",
            //     cpu: "500m"
            //   }
            // },
            env: [
              {
                name: "POSTGRES_PASSWORD",
                valueFrom: {
                  secretKeyRef: {
                    name: db_op_item.metadata.name,
                    // password
                    key: "sjdgszflp7uf27mbnmwgzmw22e",
                  }
                }
              },
              {
                name: "POSTGRES_USER",
                valueFrom: {
                  secretKeyRef: {
                    name: db_op_item.metadata.name,
                    // username
                    key: "icuusu5dutwimwq7zgjjxpzezi",
                  }
                }
              },
              {
                name: "POSTGRES_DB",
                value: db_postgres_db_name,
              }
            ],
            ports: [
              {
                containerPort: db_port,
              }
            ],
            volumeMounts: [
              {
                name: "initdb-sql",
                mountPath: "/docker-entrypoint-initdb.d",
              },
              {
                name: "postgres-persistent-storage",
                mountPath: "/var/lib/postgresql",
                subPath: "data",
              }
            ]
          }
        ],
        volumes: [
          {
            name: "postgres-persistent-storage",
            persistentVolumeClaim: {
              claimName: db_pvc_name,
            }
          },
          {
            name: "initdb-sql",
            configMap: {
              name: db_cm.metadata.name,
            }
          }
        ]
      }
    }
  }
};


// Backend API server

local deployment = {
  apiVersion: 'apps/v1',
  kind: 'Deployment',
  metadata: {
    name: (import 'config.json5').name,
    labels: {
      'app.kubernetes.io/name': (import 'config.json5').name,
    },
    annotations: {
      // https://start.1password.com/open/i?a=UWWKBI7TBZCR7JIGGPATTRJZPQ&v=tsa4qdut6lvgsrl5xvsvdnmgwe&i=7l622oxh7m6bi2p73grw35ct3y&h=my.1password.com
      'operator.1password.io/item-path': 'vaults/tsa4qdut6lvgsrl5xvsvdnmgwe/items/7l622oxh7m6bi2p73grw35ct3y',
      'operator.1password.io/item-name': (import 'config.json5').name + '-secret',
    },
  },
  spec: {
    replicas: 3,
    selector: {
      matchLabels: {
        'app.kubernetes.io/name': pod_name,
      },
    },
    template: {
      metadata: {
        labels: {
          'app.kubernetes.io/name': pod_name,
        },
      },
      spec: {
        containers: [
          {
            name: container_name,
            image: 'ghcr.io/pollenjp/sandbox-http-server-go:0.1.17',
            imagePullPolicy: 'Always',
            ports: [
              {
                containerPort: 8080,
              },
            ],
            env: [
              {
                name: 'SERVER_PORT',
                value: '8080',
              },
              {
                name: 'SAMPLE_VAR',
                valueFrom: {
                  secretKeyRef: {
                    name: (import 'config.json5').name + '-secret',
                    // username
                    key: 'w6hn6f2cayuocg22t6ye4jeily',
                  },
                },
              },
              // db connection
              {
                name: 'DB_HOST',
                value: db_svc_name,
              },
              {
                name: 'DB_PORT',
                value: std.toString(db_port),
              },
              {
                name: 'DB_NAME',
                value: db_postgres_db_name,
              },
              {
                name: 'DB_USER',
                valueFrom: {
                  secretKeyRef: {
                    name: db_op_item.metadata.name,
                    key: 'username',
                  },
                }
              },
              {
                name: 'DB_PASSWORD',
                valueFrom: {
                  secretKeyRef: {
                    name: db_op_item.metadata.name,
                    key: 'password',
                  },
                },
              },
              {
                name: 'DB_OPTIONS',
                value: 'sslmode=disable',
              },
            ],
          },
        ],
      },
    },
  },
};

local service = {
  apiVersion: 'v1',
  kind: 'Service',
  metadata: {
    name: svc_name,
    labels: {
      'app.kubernetes.io/name': svc_name,
    },
  },
  spec: {
    selector: {
      'app.kubernetes.io/name': pod_name,
    },
    ports: [
      {
        port: 8080,
        protocol: 'TCP',
        targetPort: 8080,
      },
    ],
  },
};

[
  db_op_item,
  db_cm,
  db_svc,
  db_pvc,
  db_deployment,
  deployment,
  service
]
