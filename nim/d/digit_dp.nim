const
  MaxDigits = 19
  MaxDigitSum = 171
  MaxInputLength = 4
  MinBound = -1'i64
  MaxBound = 1_000_000_000_000_000_000'i64

type I64Input = ptr UncheckedArray[int64]

proc countUpTo(boundValue: int64, target: int): int64 =
  if boundValue < 0: return 0
  var bound = boundValue
  var digits: array[MaxDigits, int]
  var digitCount = 0
  while true:
    digits[digitCount] = int(bound mod 10)
    inc digitCount
    bound = bound div 10
    if bound == 0: break

  var loose: array[MaxDigitSum + 1, int64]
  var tight: array[MaxDigitSum + 1, int64]
  tight[0] = 1
  while digitCount > 0:
    dec digitCount
    let limit = digits[digitCount]
    var nextLoose: array[MaxDigitSum + 1, int64]
    var nextTight: array[MaxDigitSum + 1, int64]
    for sum in 0 .. target:
      for digit in 0 .. min(9, target - sum):
        nextLoose[sum + digit] += loose[sum]
      for digit in 0 .. min(limit, target - sum):
        if digit == limit:
          nextTight[sum + digit] += tight[sum]
        else:
          nextLoose[sum + digit] += tight[sum]
    loose = nextLoose
    tight = nextTight
  loose[target] + tight[target]

proc digit_dp*(input: I64Input, length: csize_t): int64 {.cdecl, exportc: "digit_dp".} =
  if input == nil or length > csize_t(MaxInputLength) or length != 3: return -1
  let lower = input[0]
  let upper = input[1]
  let targetValue = input[2]
  if lower < MinBound or lower > MaxBound or upper < MinBound or upper > MaxBound: return -1
  if targetValue < int64(low(int32)) or targetValue > int64(high(int32)): return -1
  if lower > upper or targetValue < 0 or targetValue > MaxDigitSum: return 0
  let target = int(targetValue)
  countUpTo(upper, target) - countUpTo(lower - 1, target)
