## Exchange each adjacent pair of low 30 bits.
proc swap_adjacent_bits*(input: int64): int64 {.cdecl, exportc: "swap_adjacent_bits".} =
  if input < 0 or input > 1_073_741_823: return -1
  ((input and 0xAAAAAAAA'i64) shr 1) or ((input and 0x55555555'i64) shl 1)
