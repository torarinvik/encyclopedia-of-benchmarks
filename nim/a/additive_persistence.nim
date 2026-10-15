## Count repeated decimal digit-sum steps until one digit remains.
proc additive_persistence*(input_value: int64): int64 {.cdecl, exportc: "additive_persistence".} =
  if input_value < 0: return -1
  var input = input_value
  var steps = 0'i64
  while input >= 10:
    var total = 0'i64
    var remaining = input
    while remaining > 0:
      total += remaining mod 10
      remaining = remaining div 10
    input = total
    inc steps
  steps
