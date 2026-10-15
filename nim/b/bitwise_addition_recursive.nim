## Add nonnegative integers by recursively propagating XOR carries.
proc add_recursive(first, second: int64): int64 =
  let bitwiseSum = first xor second
  let carry = first and second
  if carry == 0: return bitwiseSum
  add_recursive(bitwiseSum, carry shl 1)

proc bitwise_addition_recursive*(first, second: int64): int64
    {.cdecl, exportc: "bitwise_addition_recursive".} =
  if first < 0 or first > 2_147_483_647 or second < 0 or second > 2_147_483_647: return -1
  add_recursive(first, second)
