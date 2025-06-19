// This variable is a signature to check the name is hashed by this library.
//
// metadata.name must be a valid RFC 1123 subdomain name.
// a lowercase RFC 1123 subdomain must consist of lower case alphanumeric characters,
// '-' or '.', and must start and end with an alphanumeric character
// (e.g. 'example.com', regex used for validation is '[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*')
//
// ```jsonnet
// local name = ...;
//
// local some_resource = { ... };
// local some_resource_name = name + '-' + lib_hash {data: some_resource}.output;
//
// ...
//
// [
//   std.mergePatch(some_resource, { metadata: { name: some_resource_name } }),
//   ...,
// ]
// ```
//
local hashed_sign = 'vuk4yykr';
{
  data:: error 'data is required',
  output: std.md5(std.toString($.data))[0:8] + hashed_sign,
  hashed_sign: hashed_sign,
}
