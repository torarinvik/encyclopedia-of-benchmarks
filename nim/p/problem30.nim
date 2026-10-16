proc digitFifthPower(digit: int64): int64 =
  digit * digit * digit * digit * digit

proc problem30*(ignored: int64): int64 {.cdecl, exportc: "problem30".} =
  if ignored != 0: return -1
  var total: int64 = 0
  var number: int64 = 1_000
  while number < 1_000_000:
    var remaining = number
    var digitSum: int64 = 0
    while remaining > 0:
      digitSum += digitFifthPower(remaining mod 10)
      remaining = remaining div 10
    if digitSum == number: total += number
    inc number
  total
