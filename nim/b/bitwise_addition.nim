## Add nonnegative integers with XOR and shifted AND carry propagation.
proc bitwise_addition*(first, second: uint64): int64 {.cdecl, exportc: "bitwise_addition".} =
  var left = first
  var carry_bits = second
  while carry_bits != 0:
    let carry = left and carry_bits
    left = left xor carry_bits
    carry_bits = carry shl 1
  return int64(left)
