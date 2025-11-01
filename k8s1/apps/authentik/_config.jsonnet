local argo_app_config = (import '_app_config.json');

std.mergePatch(
  argo_app_config,
  {
    // hard code: configured in helm chart
    export_svc_name: 'authentik-server', // expose from cloudflare tunnel
    // hard code: configured in helm chart
    export_svc_port: 80, // expose from cloudflare tunnel
    secret: { // https://start.1password.com/open/i?a=UWWKBI7TBZCR7JIGGPATTRJZPQ&v=tsa4qdut6lvgsrl5xvsvdnmgwe&i=tv7ap6k7v5p4yzm4dtk2kqloxu&h=my.1password.com
      // <map_key (use in jsonnet)>: {
      //   key_name: "key name in secret data",
      //   onepassword_key: "onepassword key",
      // }
      authentik_secret_key: {
        // https://github.com/goauthentik/helm/blob/0d7a6736ee1eb9fa6717a8fc6826985c45ed2e9c/charts/authentik/values.yaml#L157
        // > -- Secret key used for cookie singing and unique user IDs,
        // > don't change this after the first install
        key_name: 'authentik-secret-key',
        onepassword_key: 'tv7ap6k7v5p4yzm4dtk2kqloxu/k7zfgxdgcexlmpdytuyu4447ki/ldazxrkbvxvc3nbekh4scfx7iu',
      },
      psql_admin: {
        key_name: 'postgres-password',
        onepassword_key: 'tv7ap6k7v5p4yzm4dtk2kqloxu/k7zfgxdgcexlmpdytuyu4447ki/zq5usmpzkcketjckd5hpyzkfvu',
      },
      psql_user: {
        key_name: 'password',
        onepassword_key: 'tv7ap6k7v5p4yzm4dtk2kqloxu/k7zfgxdgcexlmpdytuyu4447ki/po6mjo6bxkff3givfgk2qwabgy',
      },
      psql_replication: {
        key_name: 'replication-password',
        onepassword_key: 'tv7ap6k7v5p4yzm4dtk2kqloxu/k7zfgxdgcexlmpdytuyu4447ki/zrcq5hwocikdmsc6ut2r7ptgmm',
      },
    },
  },
)
