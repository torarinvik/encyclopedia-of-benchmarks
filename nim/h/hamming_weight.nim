## Count set bits in an unsigned 32-bit integer.
proc hamming_weight*(value: int64): int64 {.cdecl, exportc: "hamming_weight".} =
  if value < 0 or value > 4_294_967_295'i64: return -1
  let number = uint32(value)
  var count = 0'i64
  for bit in 0 ..< 32:
    count += int64((number shr bit) and 1'u32)
  count
