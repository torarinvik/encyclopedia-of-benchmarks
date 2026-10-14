## Return the LCS length of two packed ASCII sequences.
proc longest_common_subsequence*(packed: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "longest_common_subsequence".} =
  if packed.isNil or length < 2 or length > 512: return -1
  let leftLength = packed[0]
  let rightLength = packed[1]
  if leftLength < 0 or leftLength > 255 or rightLength < 0 or rightLength > 255: return -1
  if length != csize_t(2 + leftLength + rightLength): return -1
  for index in 0 ..< int(leftLength + rightLength):
    if packed[2 + index] < 0 or packed[2 + index] > 127: return -1

  var dp: array[256, int64]
  for left in 0 ..< int(leftLength):
    var diagonal = 0'i64
    var right = 1
    while right <= int(rightLength):
      let above = dp[right]
      if packed[2 + left] == packed[2 + int(leftLength) + right - 1]:
        dp[right] = diagonal + 1
      elif dp[right - 1] > dp[right]:
        dp[right] = dp[right - 1]
      diagonal = above
      inc right
  dp[int(rightLength)]
