## Bottom-up count of ordered denomination sequences.
proc combination_sum_iv*(packed: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "combination_sum_iv".} =
  if length < 2 or length > 18:
    return low(int64)
  if packed[0] < 0 or packed[0] > 16 or packed[1] < 0 or packed[1] > 63:
    return low(int64)
  let count = int(packed[0])
  let target = int(packed[1])
  if length != csize_t(count + 2):
    return low(int64)
  for i in 0 ..< count:
    if packed[i + 2] < 1 or packed[i + 2] > 63:
      return low(int64)
    for j in 0 ..< i:
      if packed[i + 2] == packed[j + 2]:
        return low(int64)

  var dp: array[64, int64]
  dp[0] = 1
  for sum in 1 .. target:
    for i in 0 ..< count:
      let denomination = int(packed[i + 2])
      if denomination <= sum:
        dp[sum] += dp[sum - denomination]
  dp[target]
