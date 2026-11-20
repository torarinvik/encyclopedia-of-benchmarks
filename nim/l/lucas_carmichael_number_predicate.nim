const MaxValue = 1_000_000'i64

proc lucas_carmichael_number_predicate*(input: ptr int64, length: csize_t): int64
    {.cdecl, exportc: "lucas_carmichael_number_predicate".} =
  if input == nil or length != csize_t(1): return -1
  let value = input[]
  if value < 1 or value > MaxValue: return -1

  var remaining = value
  var divisor = 2'i64
  var composite = false
  while divisor <= remaining div divisor:
    if remaining mod divisor == 0:
      composite = true
      var exponent = 0
      while remaining mod divisor == 0:
        remaining = remaining div divisor
        inc exponent
      if exponent != 1 or (value + 1) mod (divisor + 1) != 0: return 0
    inc divisor
  if remaining > 1:
    if not composite or (value + 1) mod (remaining + 1) != 0: return 0
  if composite: return 1
  0
