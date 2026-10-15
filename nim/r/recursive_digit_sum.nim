## Compute the source's repeated-digit-sum result from n and k.
proc digitSum(number: int64): int64 =
  var remaining = number
  while remaining != 0:
    result += remaining mod 10
    remaining = remaining div 10
  if number == 0: 0 else: result

proc recursive_digit_sum*(number, repetitions: int64): int64
    {.cdecl, exportc: "recursive_digit_sum".} =
  if number < 0 or repetitions < 0 or repetitions > 1_000_000: return -1
  var total = digitSum(number) * repetitions
  while total >= 10:
    total = digitSum(total)
  total
