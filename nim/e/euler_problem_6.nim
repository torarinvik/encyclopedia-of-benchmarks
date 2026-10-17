const MaxN = 100'i64
const MaxValidInputLength = 1
const MaxInputLength = MaxValidInputLength + 1

proc euler_problem_6*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "euler_problem_6".} =
  if input.isNil or length < csize_t(MaxValidInputLength) or
      length > csize_t(MaxInputLength): return -1
  if length != csize_t(MaxValidInputLength): return -1
  let n = input[0]
  if n < 1'i64 or n > MaxN: return -1

  var sum = 0'i64
  var sumOfSquares = 0'i64
  var value = 1'i64
  while value <= n:
    sum += value
    sumOfSquares += value * value
    inc value
  sum * sum - sumOfSquares
