## Multiply two bounded signed operands; the bounds guarantee an i64 result.
const InvalidResult = low(int64)

proc multiply_digit*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "multiply_digit".} =
  if values == nil or length != 2: return InvalidResult
  let first = values[0]
  let second = values[1]
  if first < -1_000_000_000'i64 or first > 1_000_000_000'i64 or
      second < -1_000_000_000'i64 or second > 1_000_000_000'i64:
    return InvalidResult
  first * second
