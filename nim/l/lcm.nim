## Portable LCM with overflow checked after dividing by the GCD.
proc lcm*(left, right: uint64): int64 {.cdecl, exportc: "lcm".} =
  if left == 0 or right == 0:
    return 0
  var a = left
  var b = right
  while b != 0:
    let remainder = a mod b
    a = b
    b = remainder
  let reduced = left div a
  let maxResult = uint64(high(int64))
  if reduced > maxResult div right:
    return -1
  return int64(reduced * right)
