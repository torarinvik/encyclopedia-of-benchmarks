proc unique_subsequences_count*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "unique_subsequences_count".} =
  if input.isNil or length < 1 or length > 31: return -1
  let nValue = input[0]
  if nValue < 0 or nValue > 30 or length != csize_t(nValue + 1): return -1
  let n = int(nValue)
  for i in 0 ..< n:
    if input[i + 1] < 0 or input[i + 1] > 127: return -1
  var dp: array[31, int64]
  var endIndex = n
  while endIndex > 0:
    let i = endIndex - 1
    var seen: array[128, bool]
    for j in i ..< n:
      let ch = int(input[j + 1])
      if not seen[ch]:
        seen[ch] = true
        dp[i] += 1 + dp[j + 1]
    dec endIndex
  dp[0]
