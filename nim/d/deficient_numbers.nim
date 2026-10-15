## Proper-divisor pair scan from the pinned Python source.
proc deficient_numbers*(number: int64): int64 {.cdecl, exportc: "deficient_numbers".} =
  if number <= 0:
    return 0
  if number > 100_000_000:
    return -1
  if number == 1:
    return 1

  var total = 1'i64
  var divisor = 2'i64
  while divisor <= number div divisor:
    if number mod divisor == 0:
      let other = number div divisor
      total += divisor
      if other != divisor:
        total += other
    inc divisor
  return if total < number: 1 else: 0
