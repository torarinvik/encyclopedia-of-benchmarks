const
  MaxLimit = 10_000_000'i64
  MaxDigits = 7
  MaxSum = MaxDigits * 81 + 1

proc digitSquareSum(value: uint32): uint32 =
  var number = value
  while number != 0:
    let digit = number mod 10
    result += digit * digit
    number = number div 10

proc reaches89(value: uint32): bool =
  var number = value
  while number != 1 and number != 89:
    number = digitSquareSum(number)
  number == 89

proc problem92*(number: int64): int64 {.cdecl, exportc: "problem92".} =
  if number < 0 or number > MaxLimit: return -1
  var digits, reversed: array[MaxDigits, uint32]
  var digitCount = 0
  if number > 1:
    var remaining = uint32(number - 1)
    while remaining != 0:
      reversed[digitCount] = remaining mod 10
      inc digitCount
      remaining = remaining div 10
    for index in 0..<digitCount:
      digits[index] = reversed[digitCount - index - 1]
  else:
    digits[0] = 0
    digitCount = 1
  let sumLimit = digitCount * 81 + 1
  var tight, freeCounts, nextTight, nextFree: array[MaxSum, int64]
  tight[0] = 1
  for position in 0..<digitCount:
    for sum in 0..<MaxSum:
      nextTight[sum] = 0
      nextFree[sum] = 0
    let boundDigit = digits[position]
    for sum in 0..<sumLimit:
      if tight[sum] != 0:
        for digit in 0..int(boundDigit):
          let nextSum = sum + digit * digit
          if nextSum >= sumLimit: continue
          if uint32(digit) == boundDigit:
            nextTight[nextSum] += tight[sum]
          else:
            nextFree[nextSum] += tight[sum]
      if freeCounts[sum] != 0:
        for digit in 0..9:
          let nextSum = sum + digit * digit
          if nextSum < sumLimit: nextFree[nextSum] += freeCounts[sum]
    tight = nextTight
    freeCounts = nextFree
  var resultCount: int64 = 0
  for sum in 1..<sumLimit:
    if reaches89(uint32(sum)): resultCount += tight[sum] + freeCounts[sum]
  resultCount
