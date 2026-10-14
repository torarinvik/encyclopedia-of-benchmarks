## Portable Hamming distance over two unsigned 64-bit values.
proc hamming_distance*(left, right: uint64): int64 {.cdecl, exportc: "hamming_distance".} =
  var left_bits = left
  var right_bits = right
  var count = 0'i64
  while left_bits != 0 or right_bits != 0:
    if (left_bits and 1'u64) != (right_bits and 1'u64):
      inc count
    left_bits = left_bits shr 1
    right_bits = right_bits shr 1
  return count
