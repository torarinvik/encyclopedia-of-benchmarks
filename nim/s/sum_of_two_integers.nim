## Add two signed i32 operands with XOR and shifted carry in a 64-bit word.
proc bitwiseAdd(a, b: int64): int64 =
  var left = cast[uint64](a)
  var right = cast[uint64](b)
  while right != 0:
    let partial = left xor right
    right = (left and right) shl 1
    left = partial
  cast[int64](left)

proc sum_of_two_integers*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "sum_of_two_integers".} =
  if values == nil or length != 2: return -1
  if values[0] < int64(low(int32)) or values[0] > int64(high(int32)) or
      values[1] < int64(low(int32)) or values[1] > int64(high(int32)): return -1
  bitwiseAdd(values[0], values[1])
