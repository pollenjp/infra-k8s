# Changelog

## [1.3.0](https://github.com/pollenjp/infra-k8s/compare/v1.2.0...v1.3.0) (2025-09-28)


### Features

* **argocd:** restructuring to '_app_config.json' ([c0f2a7d](https://github.com/pollenjp/infra-k8s/commit/c0f2a7dd2cf472d4d02f336c145fb62df18d8870))
* **ci:** add release-please ([866a823](https://github.com/pollenjp/infra-k8s/commit/866a8234f930040596bb69a7c7760e600b3ba38f))
* **grafana-k8s-monitoring:** add sandbox-nginx namespace to target namespaces ([28970bd](https://github.com/pollenjp/infra-k8s/commit/28970bdcc5beb556fb96f2e66a6f23473317e4c2))
* **grafana-mimir:** init ([d8b80f6](https://github.com/pollenjp/infra-k8s/commit/d8b80f61339893f634332da5258fd5545a8e3b6e))
* **k8s-monitoring:** add echo-slack-bot-rs namespace ([63621c8](https://github.com/pollenjp/infra-k8s/commit/63621c8d20cd85a7be5f9b2ff6287e66be69cec9))
* **k8s1-cf-tunnel:** add myminio-console ([b5e31d1](https://github.com/pollenjp/infra-k8s/commit/b5e31d1c6b687e511ff4b6286d673d6464e29ced))
* **k8s1-cf-tunnel:** update minio-tenant-1 ingress ([03dbb0d](https://github.com/pollenjp/infra-k8s/commit/03dbb0d671d20d0e24781dbdc93032594fdda7ab))
* **loki,prometheus:** add retention config ([49abc90](https://github.com/pollenjp/infra-k8s/commit/49abc90d2241923cf39e307918057c39adcdbc06))
* **loki:** introduce minio sts ([33ef794](https://github.com/pollenjp/infra-k8s/commit/33ef79487e79485a929a2879ce05e28b7a044d27))
* **loki:** minio sts ([1ce539c](https://github.com/pollenjp/infra-k8s/commit/1ce539c9a6be8086e88f0a9926356a88fc4e11b3))
* **mimir:** fix kafka retention and mimir max_global_series_per_user ([750ccb0](https://github.com/pollenjp/infra-k8s/commit/750ccb04e0528f5c48b4f933aaf76bc7cdc47a9a))
* **mimir:** fix kafka's retention configuration ([4cd4e1d](https://github.com/pollenjp/infra-k8s/commit/4cd4e1d4424c6092b21cdb78e0936c90e8915d6c))
* **mimir:** set mimir to prometheus target ([8520cef](https://github.com/pollenjp/infra-k8s/commit/8520cef88068aa95b04296d44ab0bb57fcbad04e))
* **minio-operator:** add ([69dca92](https://github.com/pollenjp/infra-k8s/commit/69dca92cce9e974c43d2de5e1a50813a9890f54a))
* **minio-operator:** add cert-manager tls certificate ([b40567d](https://github.com/pollenjp/infra-k8s/commit/b40567d033e7cc8db1d87d6f6c6f03b9c533edf0))
* **minio-tenant-1:** add bucket names for Loki configuration ([35ae323](https://github.com/pollenjp/infra-k8s/commit/35ae32325f80919fdd3a925d13fc8ff5a260aab9))
* **minio-tenant-1:** add ExternalSecret and ServiceAccount for operator CA TLS configuration ([5b8dfa2](https://github.com/pollenjp/infra-k8s/commit/5b8dfa26e97cd80c422f24125184999067726362))
* **minio-tenant-1:** add pool 2 ([9ef5b71](https://github.com/pollenjp/infra-k8s/commit/9ef5b71763a6e2341b23d87b00bf3393d6e8b8f5))
* **minio-tenant-1:** add tenant with crd ([818b3c6](https://github.com/pollenjp/infra-k8s/commit/818b3c6e69b13116fe9ed00733fc81c05d9cabeb))
* **minio-tenant-1:** add user0 ([9dbf201](https://github.com/pollenjp/infra-k8s/commit/9dbf20175777ce07b214ff096c8edb6c723f63ff))
* **minio-tenant-1:** disable tls ([7989c48](https://github.com/pollenjp/infra-k8s/commit/7989c48ff380a8dc408e2e4877bd7289d495f09d))
* **minio-tenant:** add initial configuration and manifests for MinIO tenant deployment ([ccbbf50](https://github.com/pollenjp/infra-k8s/commit/ccbbf509ec9316f364250195ce48fcca1d4efbd4))
* **minio-tenant:** add tenant_name configuration and update manifests ([4019d48](https://github.com/pollenjp/infra-k8s/commit/4019d48dde2c51259a4f38d6498b52637f2d8b04))
* **minio-tenant:** customize rootUser / rootPassword ([7fa1810](https://github.com/pollenjp/infra-k8s/commit/7fa1810a884d6681c9e4d9a189cc65a857f5257c))
* **sandbox-http-server-go1:** use lib_hash2 ([ea10565](https://github.com/pollenjp/infra-k8s/commit/ea10565f0a665c01f4a02fc87e82790ca443f9b3))
* **trust-manager:** add initial configuration and manifests for trust-manager application ([d2f0bcc](https://github.com/pollenjp/infra-k8s/commit/d2f0bcccfaca27e9d33bb4549093a6d5e8f0c51d))


### Bug Fixes

* **grafana-loki:** use lib_hash2 for minio_ex_secret ([7cbcc1a](https://github.com/pollenjp/infra-k8s/commit/7cbcc1aa75db7edae16c37da9fe2755671fb6b5f))
* **loki:** minio auth (not completed) ([83b9c1e](https://github.com/pollenjp/infra-k8s/commit/83b9c1e61b848660fd856c495d7899658798fa67))
* **minio-tenant-1:** update ExternalSecret name and console access key for user0 ([c4cca4d](https://github.com/pollenjp/infra-k8s/commit/c4cca4d37b05a57a9ac7ffa976ba428fa6a6caa7))
* use libhash2 instead of libhash ([ed012a4](https://github.com/pollenjp/infra-k8s/commit/ed012a44342026d87d935a39a1fe7afe176ee65c))

## [1.2.0](https://github.com/pollenjp/infra-k8s/compare/v1.1.0...v1.2.0) (2025-09-24)


### Features

* **argocd:** restructuring to '_app_config.json' ([c0f2a7d](https://github.com/pollenjp/infra-k8s/commit/c0f2a7dd2cf472d4d02f336c145fb62df18d8870))
* **mimir:** fix kafka's retention configuration ([4cd4e1d](https://github.com/pollenjp/infra-k8s/commit/4cd4e1d4424c6092b21cdb78e0936c90e8915d6c))

## [1.1.0](https://github.com/pollenjp/infra-k8s/compare/v1.0.0...v1.1.0) (2025-09-22)


### Features

* **grafana-mimir:** init ([d8b80f6](https://github.com/pollenjp/infra-k8s/commit/d8b80f61339893f634332da5258fd5545a8e3b6e))
* **loki,prometheus:** add retention config ([49abc90](https://github.com/pollenjp/infra-k8s/commit/49abc90d2241923cf39e307918057c39adcdbc06))
* **mimir:** fix kafka retention and mimir max_global_series_per_user ([750ccb0](https://github.com/pollenjp/infra-k8s/commit/750ccb04e0528f5c48b4f933aaf76bc7cdc47a9a))
* **mimir:** set mimir to prometheus target ([8520cef](https://github.com/pollenjp/infra-k8s/commit/8520cef88068aa95b04296d44ab0bb57fcbad04e))

## 1.0.0 (2025-09-07)


### Features

* **ci:** add release-please ([866a823](https://github.com/pollenjp/infra-k8s/commit/866a8234f930040596bb69a7c7760e600b3ba38f))
* **grafana-k8s-monitoring:** add sandbox-nginx namespace to target namespaces ([28970bd](https://github.com/pollenjp/infra-k8s/commit/28970bdcc5beb556fb96f2e66a6f23473317e4c2))
* **k8s-monitoring:** add echo-slack-bot-rs namespace ([63621c8](https://github.com/pollenjp/infra-k8s/commit/63621c8d20cd85a7be5f9b2ff6287e66be69cec9))
* **k8s1-cf-tunnel:** add myminio-console ([b5e31d1](https://github.com/pollenjp/infra-k8s/commit/b5e31d1c6b687e511ff4b6286d673d6464e29ced))
* **k8s1-cf-tunnel:** update minio-tenant-1 ingress ([03dbb0d](https://github.com/pollenjp/infra-k8s/commit/03dbb0d671d20d0e24781dbdc93032594fdda7ab))
* **loki:** introduce minio sts ([33ef794](https://github.com/pollenjp/infra-k8s/commit/33ef79487e79485a929a2879ce05e28b7a044d27))
* **loki:** minio sts ([1ce539c](https://github.com/pollenjp/infra-k8s/commit/1ce539c9a6be8086e88f0a9926356a88fc4e11b3))
* **minio-operator:** add ([69dca92](https://github.com/pollenjp/infra-k8s/commit/69dca92cce9e974c43d2de5e1a50813a9890f54a))
* **minio-operator:** add cert-manager tls certificate ([b40567d](https://github.com/pollenjp/infra-k8s/commit/b40567d033e7cc8db1d87d6f6c6f03b9c533edf0))
* **minio-tenant-1:** add bucket names for Loki configuration ([35ae323](https://github.com/pollenjp/infra-k8s/commit/35ae32325f80919fdd3a925d13fc8ff5a260aab9))
* **minio-tenant-1:** add ExternalSecret and ServiceAccount for operator CA TLS configuration ([5b8dfa2](https://github.com/pollenjp/infra-k8s/commit/5b8dfa26e97cd80c422f24125184999067726362))
* **minio-tenant-1:** add tenant with crd ([818b3c6](https://github.com/pollenjp/infra-k8s/commit/818b3c6e69b13116fe9ed00733fc81c05d9cabeb))
* **minio-tenant-1:** add user0 ([9dbf201](https://github.com/pollenjp/infra-k8s/commit/9dbf20175777ce07b214ff096c8edb6c723f63ff))
* **minio-tenant-1:** disable tls ([7989c48](https://github.com/pollenjp/infra-k8s/commit/7989c48ff380a8dc408e2e4877bd7289d495f09d))
* **minio-tenant:** add initial configuration and manifests for MinIO tenant deployment ([ccbbf50](https://github.com/pollenjp/infra-k8s/commit/ccbbf509ec9316f364250195ce48fcca1d4efbd4))
* **minio-tenant:** add tenant_name configuration and update manifests ([4019d48](https://github.com/pollenjp/infra-k8s/commit/4019d48dde2c51259a4f38d6498b52637f2d8b04))
* **minio-tenant:** customize rootUser / rootPassword ([7fa1810](https://github.com/pollenjp/infra-k8s/commit/7fa1810a884d6681c9e4d9a189cc65a857f5257c))
* **sandbox-http-server-go1:** use lib_hash2 ([ea10565](https://github.com/pollenjp/infra-k8s/commit/ea10565f0a665c01f4a02fc87e82790ca443f9b3))
* **trust-manager:** add initial configuration and manifests for trust-manager application ([d2f0bcc](https://github.com/pollenjp/infra-k8s/commit/d2f0bcccfaca27e9d33bb4549093a6d5e8f0c51d))


### Bug Fixes

* **grafana-loki:** use lib_hash2 for minio_ex_secret ([7cbcc1a](https://github.com/pollenjp/infra-k8s/commit/7cbcc1aa75db7edae16c37da9fe2755671fb6b5f))
* **loki:** minio auth (not completed) ([83b9c1e](https://github.com/pollenjp/infra-k8s/commit/83b9c1e61b848660fd856c495d7899658798fa67))
* **minio-tenant-1:** update ExternalSecret name and console access key for user0 ([c4cca4d](https://github.com/pollenjp/infra-k8s/commit/c4cca4d37b05a57a9ac7ffa976ba428fa6a6caa7))
* use libhash2 instead of libhash ([ed012a4](https://github.com/pollenjp/infra-k8s/commit/ed012a44342026d87d935a39a1fe7afe176ee65c))
