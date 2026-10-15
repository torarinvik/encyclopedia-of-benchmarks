## Check whether the packed values match the generated Golomb prefix.
const MaxN = 1024

proc golomb_sequence_validator*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "golomb_sequence_validator".} =
  if length < 1 or length > csize_t(MaxN): return -1
  if input[0] < 1 or input[0] > MaxN: return -1
  let n = int(input[0])
  if int(length) != n: return -1
  for index in 1 ..< n:
    if input[index] < -2147483648 or input[index] > 2147483647: return -1

  var dp: array[MaxN, int64]
  dp[0] = 1
  for i in 1 ..< n:
    let previous = int(dp[i - 1])
    let nested = int(dp[previous])
    let source = i - nested
    dp[i] = 1 + dp[source]
  for index in 1 ..< n:
    if input[index] != dp[index]: return 0
  1
