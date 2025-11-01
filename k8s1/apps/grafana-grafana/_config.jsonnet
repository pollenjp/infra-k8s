local argo_app_config = (import '_app_config.json');

std.mergePatch(
  argo_app_config,
  {
    secret: { // https://start.1password.com/open/i?a=UWWKBI7TBZCR7JIGGPATTRJZPQ&v=tsa4qdut6lvgsrl5xvsvdnmgwe&i=tibvxjoy34cu3sc5vhfri6cf2u&h=my.1password.com
      // <map_key (use in jsonnet)>: {
      //   key_name: "key name in secret data",
      //   onepassword_key: "onepassword key",
      // }
      admin_username: {
        key_name: 'username',
        onepassword_key: 'tibvxjoy34cu3sc5vhfri6cf2u/gkpou4obtm56pmou7vowkkf6ti/sgcp22454qyofi6gbqa4z45voa',
      },
      admin_password: {
        key_name: 'password',
        onepassword_key: 'tibvxjoy34cu3sc5vhfri6cf2u/gkpou4obtm56pmou7vowkkf6ti/mc465ae7z6nypydq7h6krm3q5a',
      },
    },
  },
)
