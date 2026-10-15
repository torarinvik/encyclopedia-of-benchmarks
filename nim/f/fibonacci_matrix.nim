const MaxIndex = 92'i64

proc fibonacci_matrix*(index: int64): int64 {.cdecl, exportc: "fibonacci_matrix".} =
  if index < 0 or index > MaxIndex: return -1
  if index == 0: return 0
  var r00 = 1'i64
  var r01 = 0'i64
  var r10 = 0'i64
  var r11 = 1'i64
  var b00 = 1'i64
  var b01 = 1'i64
  var b10 = 1'i64
  var b11 = 0'i64
  var exponent = index - 1
  while exponent > 0:
    if exponent mod 2 == 1:
      let n00 = r00 * b00 + r01 * b10
      let n01 = r00 * b01 + r01 * b11
      let n10 = r10 * b00 + r11 * b10
      let n11 = r10 * b01 + r11 * b11
      r00 = n00; r01 = n01; r10 = n10; r11 = n11
      dec exponent
    else:
      let n00 = b00 * b00 + b01 * b10
      let n01 = b00 * b01 + b01 * b11
      let n10 = b10 * b00 + b11 * b10
      let n11 = b10 * b01 + b11 * b11
      b00 = n00; b01 = n01; b10 = n10; b11 = n11
      exponent = exponent div 2
  r00
