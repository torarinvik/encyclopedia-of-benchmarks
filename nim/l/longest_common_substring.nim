const MaxLength = 256

proc longest_common_substring*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "longest_common_substring".} =
  if input == nil or length < 2 or input[0] < 0 or input[0] > MaxLength: return -1
  let firstLength = int(input[0])
  if firstLength + 2 > int(length) or input[firstLength + 1] < 0 or input[firstLength + 1] > MaxLength: return -1
  let secondLength = int(input[firstLength + 1])
  if int(length) != firstLength + secondLength + 2: return -1
  let first = firstLength + 1
  let second = firstLength + 2
  for i in 0 ..< firstLength:
    if input[first + i] < 32 or input[first + i] > 126: return -1
  for j in 0 ..< secondLength:
    if input[second + j] < 32 or input[second + j] > 126: return -1
  var dp: array[MaxLength + 1, int64]
  var best = 0'i64
  for i in 1 .. firstLength:
    var j = secondLength
    while j > 0:
      if input[first + i - 1] == input[second + j - 1]:
        dp[j] = dp[j - 1] + 1
        if dp[j] > best: best = dp[j]
      else: dp[j] = 0
      dec j
  best
