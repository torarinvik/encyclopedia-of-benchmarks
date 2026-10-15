## Return shortest common supersequence length for two packed ASCII sequences.
proc shortest_common_supersequence_length*(packed: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "shortest_common_supersequence_length".} =
  if packed.isNil or length < 2 or length > 512: return -1
  let m = packed[0]
  let n = packed[1]
  if m < 0 or m > 255 or n < 0 or n > 255: return -1
  if length != csize_t(2 + m + n): return -1
  for k in 0 ..< int(m + n):
    if packed[2 + k] < 0 or packed[2 + k] > 127: return -1

  let columns = int(n) + 1
  var dp: array[65536, int64]
  for i in 1 .. int(m):
    for j in 1 .. int(n):
      let cell = i * columns + j
      if packed[1 + i] == packed[1 + int(m) + j]:
        dp[cell] = dp[(i - 1) * columns + j - 1] + 1
      else:
        dp[cell] = max(dp[(i - 1) * columns + j], dp[i * columns + j - 1])
  m + n - dp[int(m) * columns + int(n)]
