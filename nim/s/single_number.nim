## XOR reduction for the signed 32-bit single-number contract.
proc single_number*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "single_number".} =
  if length == 0 or length > 257: return -2147483649'i64
  var bits: int64 = 0
  for i in 0 ..< length:
    let value = values[i]
    if value < -2147483648'i64 or value > 2147483647'i64: return -2147483649'i64
    let word = if value < 0: value + 4294967296'i64 else: value
    bits = bits xor word
  if bits > 2147483647'i64: bits - 4294967296'i64 else: bits
