const Int32MinValue = -2_147_483_648'i64
const Int32MaxValue = 2_147_483_647'i64

## Zero-based trailing set-bit index using the Java magnitude behavior.
proc index_of_right_most_set_bit*(value: int64): int64 {.cdecl, exportc: "index_of_right_most_set_bit".} =
  if value < Int32MinValue or value > Int32MaxValue or value == 0: return -1
  var magnitude = if value < 0: -value else: value
  var index = 0'i64
  while magnitude mod 2 == 0:
    magnitude = magnitude div 2
    inc index
  index
