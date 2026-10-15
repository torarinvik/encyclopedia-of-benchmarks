## Rotate a 32-bit word right and return its unsigned value in int64.
proc rotate_right32*(value, shift: uint64): int64 {.cdecl, exportc: "rotate_right32".} =
  if value > 0xFFFF_FFFF'u64 or shift > 0x7FFF_FFFF'u64: return -1
  let bits = uint32(value)
  let amount = int(shift mod 32)
  if amount == 0: return int64(bits)
  int64((bits shr amount) or (bits shl (32 - amount)))
