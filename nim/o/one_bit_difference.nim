proc one_bit_difference*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "one_bit_difference".} =
  if input == nil or length != 2: return -1
  let left = input[0]
  let right = input[1]
  if left < -2147483648'i64 or left > 2147483647'i64 or right < -2147483648'i64 or right > 2147483647'i64: return -1
  let difference = cast[uint32](int32(left)) xor cast[uint32](int32(right))
  if difference != 0 and (difference and (difference - 1'u32)) == 0: return 1
  return 0
