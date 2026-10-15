## Overflow-safe floor arithmetic mean using the bitwise identity.
const MaxValue = 9_000_000_000_000_000_000'i64

proc arithmeticmean*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "arithmeticmean".} =
  if length != 2 or values == nil: return -1
  let left = values[0]
  let right = values[1]
  if left < 0 or left > MaxValue or right < 0 or right > MaxValue: return -1
  ((left xor right) shr 1) + (left and right)
