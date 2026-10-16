## Simple iterative modular inverse for bounded coprime positive inputs.
proc gcdU64(leftInput, rightInput: int64): int64 =
  var left = leftInput
  var right = rightInput
  while right != 0:
    let remainder = left mod right
    left = right
    right = remainder
  left

proc modular_inverse_simple*(x, y: int64): int64
    {.cdecl, exportc: "modular_inverse_simple".} =
  if x < 1 or x > 999 or y < 2 or y > 1000: return -1
  if gcdU64(x, y) != 1: return -1
  var auxiliary = 0'i64
  var iteration = 0'i64
  while true:
    auxiliary = y * iteration + 1
    inc iteration
    if auxiliary mod x == 0: break
  auxiliary div x
