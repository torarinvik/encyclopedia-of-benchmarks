proc signed_sum_from_bits(bits: uint32): int64 =
  if bits <= 2_147_483_647'u32:
    return int64(bits)
  return int64(bits) - 4_294_967_296'i64

proc is_signed_i32_encoding(value: uint64): bool =
  value <= 2_147_483_647'u64 or value >= uint64.high - 2_147_483_647'u64

proc addition_without_arithmetic*(left_encoded, right_encoded: uint64): int64 {.cdecl, exportc: "addition_without_arithmetic".} =
  if not is_signed_i32_encoding(left_encoded) or not is_signed_i32_encoding(right_encoded):
    return -1
  let left_value = signed_sum_from_bits(uint32(left_encoded and 0xFFFF_FFFF'u64))
  let right_value = signed_sum_from_bits(uint32(right_encoded and 0xFFFF_FFFF'u64))
  var left = uint32(left_encoded and 0xFFFF_FFFF'u64)
  var right = uint32(right_encoded and 0xFFFF_FFFF'u64)
  while right != 0'u32:
    let carry = left and right
    left = left xor right
    right = carry shl 1
  let sum_value = signed_sum_from_bits(left)
  if (left_value < 0) == (right_value < 0) and (sum_value < 0) != (left_value < 0):
    return -1
  return sum_value
