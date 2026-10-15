proc uniform_numbers*(value: int64): int64 {.cdecl, exportc: "uniform_numbers".} =
  if value < 0 or value > 999_999_999: return -1
  var remaining = value
  var firstDigit = 0'i64
  var digits = 0'i64
  while true:
    firstDigit = remaining mod 10
    remaining = remaining div 10
    inc digits
    if remaining == 0: break
  var repeated = 0'i64
  for _ in 0'i64 ..< digits: repeated = repeated * 10 + firstDigit
  let count = (digits - 1) * 9
  count + (if repeated <= value: firstDigit else: firstDigit - 1)
