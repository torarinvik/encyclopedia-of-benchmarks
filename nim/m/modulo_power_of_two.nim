## Java-compatible low-bit mask for a signed 32-bit input and exponent 1..31.
proc modulo_power_of_two*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "modulo_power_of_two".} =
  if length != 2 or values == nil: return -1
  let x = values[0]
  let exponent = values[1]
  if x < -2_147_483_648'i64 or x > 2_147_483_647'i64 or exponent < 1 or exponent > 31: return -1
  let mask = (1'i64 shl int(exponent)) - 1
  x and mask
