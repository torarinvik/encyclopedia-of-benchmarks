## Binary exponentiation under a positive signed 32-bit modulus.
proc modular_exponentiation*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "modular_exponentiation".} =
  if values == nil or length != 3: return -1
  let baseInput = values[0]
  let exponentInput = values[1]
  let modulus = values[2]
  if baseInput < -2147483648'i64 or baseInput > 2147483647'i64 or
      exponentInput < 0 or exponentInput > 2147483647'i64 or modulus < 1 or modulus > 2147483647'i64: return -1
  var base = baseInput mod modulus
  if base < 0: base += modulus
  var exponent = uint64(exponentInput)
  var result = 1'i64 mod modulus
  while exponent != 0:
    if (exponent and 1'u64) != 0: result = (result * base) mod modulus
    base = (base * base) mod modulus
    exponent = exponent shr 1
  result
