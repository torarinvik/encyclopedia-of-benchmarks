proc trailing_zeros(value: uint64): int =
  var current = value
  while (current and 1'u64) == 0:
    current = current shr 1
    inc result

proc bitwise_gcd*(left, right: uint64): int64 {.cdecl, exportc: "bitwise_gcd".} =
  if left == 0: return int64(right)
  if right == 0: return int64(left)

  let common_twos = trailing_zeros(left or right)
  var a = left shr trailing_zeros(left)
  var b = right
  while b != 0:
    b = b shr trailing_zeros(b)
    if a > b:
      swap(a, b)
    b = b - a
  return int64(a shl common_twos)
