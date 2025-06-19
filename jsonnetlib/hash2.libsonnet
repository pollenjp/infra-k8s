// This variable is a signature to check the name is hashed by this library.
//
// metadata.name must be a valid RFC 1123 subdomain name.
// a lowercase RFC 1123 subdomain must consist of lower case alphanumeric characters,
// '-' or '.', and must start and end with an alphanumeric character
// (e.g. 'example.com', regex used for validation is '[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*')
//
// ```jsonnet
// local lib_hash2 = import 'path/to/hash2.libsonnet';
//
// local some_resource = lib_hash2 { data: {
//   ...,
//   metadata: {
//     name: 'some-resource-name',                    // <- add hash to here
//     annotations: {
//       'kubernetes.io/name': 'some-resource-name',  // <- add hash to here
//                                                    //    Automatically added by this library
//                                                    //    If already exists, it will be overwritten
//     },
//   },
//   ...,
// }}.output;
// ```
//
local hashed_sign = 'vuk4yykr';
{
  data:: error 'data is required',
  output: (
    local name = $.data.metadata.name + '-' + std.md5(std.toString($.data))[0:8] + hashed_sign;
    std.mergePatch($.data, {
      metadata: {
        name: name,
        annotations: {
          'kubernetes.io/name': name,
        },
      },
    })
  ),
  hashed_sign: hashed_sign,
}
