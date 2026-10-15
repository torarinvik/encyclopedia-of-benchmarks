## Preserve Java int wraparound using recursive XOR and shifted carry.
proc addRecursive(a, b: uint32): uint32 =
  if b == 0: return a
  addRecursive(a xor b, (a and b) shl 1)

proc sum_without_arithmetic_operators*(a, b: int64): int64 {.cdecl, exportc: "sum_without_arithmetic_operators".} =
  if a < -2_147_483_648'i64 or a > 2_147_483_647'i64 or b < -2_147_483_648'i64 or b > 2_147_483_647'i64: return -2_147_483_649'i64
  let bits = addRecursive(cast[uint32](int32(a)), cast[uint32](int32(b)))
  if bits <= 2_147_483_647'u32: return int64(bits)
  int64(bits) - 4_294_967_296'i64
