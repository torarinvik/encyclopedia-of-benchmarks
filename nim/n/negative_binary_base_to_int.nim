## Interpret most-significant-first bits in radix -2 with checked i64 folding.
proc negative_binary_base_to_int*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "negative_binary_base_to_int".} =
  if input == nil or length < 1 or length > 63: return -1
  var value: int64 = 0
  for index in 0 ..< int(length):
    let bit = input[index]
    if bit != 0 and bit != 1: return -1
    if value > 4611686018427387904'i64 or value < -4611686018427387903'i64: return -1
    value = value * -2 + bit
  value
