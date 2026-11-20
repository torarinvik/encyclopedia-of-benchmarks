const
  MaxN = 100_000'i64
  MaxParseableLength = 2

proc factorSumCounted(valueArg: int64): int64 =
  var value = valueArg
  var total = 0'i64
  var divisor = 2'i64
  while divisor <= value div divisor:
    while value mod divisor == 0:
      total += divisor
      value = value div divisor
    inc divisor
  if value > 1: total += value
  total

proc ruth_aaron_number_predicate*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "ruth_aaron_number_predicate".} =
  if input.isNil or length < 1 or length > csize_t(MaxParseableLength): return -1
  if length != 1 or input[0] < 1 or input[0] > MaxN: return -1
  let n = input[0]
  if factorSumCounted(n) == factorSumCounted(n + 1): return 1
  0
