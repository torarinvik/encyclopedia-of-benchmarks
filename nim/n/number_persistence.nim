## Multiplicative persistence for nonnegative Java int inputs.
proc number_persistence*(input_value: int64): int64 {.cdecl, exportc: "number_persistence".} =
  if input_value < 0 or input_value > 2_147_483_647: return -1
  var input = input_value
  var steps = 0'i64
  while input >= 10:
    var product = 1'i64
    var remaining = input
    while remaining > 0:
      product *= remaining mod 10
      remaining = remaining div 10
    input = product
    inc steps
  steps
