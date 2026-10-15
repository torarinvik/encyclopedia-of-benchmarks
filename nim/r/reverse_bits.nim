## Reverse the bit order of an unsigned 32-bit word.
proc reverse_bits*(value: int64): int64 {.cdecl, exportc: "reverse_bits".} =
  if value < 0 or value > 4_294_967_295'i64: return -1
  var remaining = uint32(value)
  var reversed = 0'u32
  for bit in 0 ..< 32:
    reversed = (reversed shl 1) or (remaining and 1'u32)
    remaining = remaining shr 1
  int64(reversed)
