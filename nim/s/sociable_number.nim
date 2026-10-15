## Exact-cycle sociable-number check adapted from the pinned Java source.
proc sumProperDivisors(number: uint64): uint64 =
  if number <= 1:
    return 0
  var total = 1'u64
  var divisor = 2'u64
  while divisor <= number div divisor:
    if number mod divisor == 0:
      let other = number div divisor
      total += divisor
      if other != divisor:
        total += other
    inc divisor
  return total

proc sociable_number*(number, cycle_length: uint64): int64 {.cdecl, exportc: "sociable_number".} =
  if number == 0 or number > 100_000 or cycle_length < 2 or cycle_length > 3:
    return -1
  var current = number
  var step = 0'u64
  while step < cycle_length:
    current = sumProperDivisors(current)
    if current == number:
      if step == cycle_length - 1:
        return 1
      return 0
    inc step
  return 0
