local lib_hash = (import '../../../jsonnetlib/hash.libsonnet');

local name = (import '_app_config.json').name;

local op_item = {
  apiVersion: 'onepassword.com/v1',
  kind: 'OnePasswordItem',
  metadata: {
    name: 'dummy',
  },
  spec: {
    // https://start.1password.com/open/i?a=UWWKBI7TBZCR7JIGGPATTRJZPQ&v=tsa4qdut6lvgsrl5xvsvdnmgwe&i=twczni2zqyzzebdfeoiuqxylj4&h=my.1password.com
    itemPath: 'vaults/tsa4qdut6lvgsrl5xvsvdnmgwe/items/twczni2zqyzzebdfeoiuqxylj4',
  },
};
local op_item_name = name + '-' + lib_hash {data: op_item}.output;

[
  std.mergePatch(op_item, { metadata: { name: op_item_name } }),
]
