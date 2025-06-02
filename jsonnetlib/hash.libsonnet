// This variable is a signature to check the name is hashed by this library.
local hashed_sign = 'VuK4yyKR';
{
  data:: error 'data is required',
  output: std.md5(std.toString($.data))[0:8] + hashed_sign,
  hashed_sign: hashed_sign,
}
