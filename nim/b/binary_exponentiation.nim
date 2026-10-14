## Exponentiation by squaring with exact signed i64 overflow detection.
proc binary_exponentiation*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "binary_exponentiation".} =
  if values == nil or length != 2: return -1
  let baseInput = values[0]
  let exponentInput = values[1]
  if baseInput < 0 or baseInput > 2147483647'i64 or exponentInput < 0 or exponentInput > 2147483647'i64: return -1
  var base = uint64(baseInput)
  var exponent = uint64(exponentInput)
  var result = 1'u64
  let maximum = uint64(high(int64))
  while exponent != 0:
    if (exponent and 1'u64) != 0:
      if base != 0 and result > maximum div base: return -1
      result *= base
    exponent = exponent shr 1
    if exponent != 0:
      if base != 0 and base > maximum div base: return -1
      base *= base
  int64(result)
