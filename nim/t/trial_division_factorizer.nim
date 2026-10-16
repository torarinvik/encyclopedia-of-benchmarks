proc trial_division_factorizer*(input: int64): int64
    {.cdecl, exportc: "trial_division_factorizer".} =
  if input < -2_147_483_648'i64 or input > 2_147_483_647'i64 or input == 0 or input == -2_147_483_648'i64:
    return -1
  let number = abs(input)
  var divisor = 2'i64
  while divisor <= number div divisor:
    if number mod divisor == 0:
      return divisor
    inc divisor
  0
