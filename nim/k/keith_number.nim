proc keith_number*(number: int64): int64 {.cdecl, exportc: "keith_number".} =
  if number < 10 or number > 999999: return -1

  var reversed: array[6, int64]
  var digits: array[6, int64]
  var value = number
  var digitCount = 0
  while value > 0:
    reversed[digitCount] = value mod 10
    inc digitCount
    value = value div 10
  var total = 0'i64
  for i in 0 ..< digitCount:
    digits[i] = reversed[digitCount - 1 - i]
    total += digits[i]

  var oldest = 0
  while true:
    let next = total
    if next >= number:
      return if next == number: 1 else: 0
    total = total - digits[oldest] + next
    digits[oldest] = next
    oldest = (oldest + 1) mod digitCount
