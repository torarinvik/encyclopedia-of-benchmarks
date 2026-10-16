proc gcd(left, right: int64): int64 =
  var a = left
  var b = right
  while b != 0:
    let remainder = a mod b
    a = b
    b = remainder
  a

proc problem5*(limit: int64): int64 {.cdecl, exportc: "problem5".} =
  if limit < 1 or limit > 20: return -1
  var result = 1'i64
  for value in 2'i64..limit:
    result = (result div gcd(result, value)) * value
  result
