const DIGIT_FACTORIALS: array[10, int64] = [1'i64, 1, 2, 6, 24, 120, 720, 5040, 40320, 362880]

proc problem34*(ignored: int64): int64 {.cdecl, exportc: "problem34".} =
  if ignored != 0: return -1
  var total: int64 = 0
  var number: int64 = 3
  while number <= 2_540_160:
    var remaining = number
    var digitSum: int64 = 0
    while remaining > 0:
      digitSum += DIGIT_FACTORIALS[int(remaining mod 10)]
      remaining = remaining div 10
    if digitSum == number: total += number
    inc number
  total
