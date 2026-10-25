const MaxN = 64
const MaxInputLength = 1 + MaxN
const MaxValue = 1_000_000'i64

proc tsvc_s3111_positive_value_sum*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "tsvc_s3111_positive_value_sum".} =
  if input == nil or length < 1 or length > csize_t(MaxInputLength): return -1
  let nValue = input[0]
  if nValue < 0 or nValue > MaxN: return -1
  let n = int(nValue)
  if int(length) != 1 + n: return -1

  var sum: int64 = 0
  for i in 0 ..< n:
    let value = input[i + 1]
    if value < -MaxValue or value > MaxValue: return -1
    if value > 0: sum += value
  sum
