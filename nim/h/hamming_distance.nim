import std/bitops

proc hamming_distance*(left, right: uint64): int64 {.cdecl, exportc: "hamming_distance".} =
  countSetBits(left xor right).int64
