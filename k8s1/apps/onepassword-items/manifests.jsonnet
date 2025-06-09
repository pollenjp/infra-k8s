local name = (import 'config.json5').name;

local op_item = {
  apiVersion: 'onepassword.com/v1',
  kind: 'OnePasswordItem',
  metadata: {
    name: name,
  },
  spec: {
    // https://start.1password.com/open/i?a=UWWKBI7TBZCR7JIGGPATTRJZPQ&v=tsa4qdut6lvgsrl5xvsvdnmgwe&i=twczni2zqyzzebdfeoiuqxylj4&h=my.1password.com
    itemPath: 'vaults/tsa4qdut6lvgsrl5xvsvdnmgwe/items/twczni2zqyzzebdfeoiuqxylj4',
  },
};

[
  op_item,
]
