## Return the length of a strictly increasing subsequence.
proc longest_increasing_subsequence*(values: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "longest_increasing_subsequence".} =
  if length > 512: return -1
  var dp: array[512, int64]
  var longest = 0'i64
  for index in 0 ..< int(length):
    dp[index] = 1
    for previous in 0 ..< index:
      if values[index] > values[previous] and dp[index] < dp[previous] + 1:
        dp[index] = dp[previous] + 1
    if dp[index] > longest: longest = dp[index]
  return longest
