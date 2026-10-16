## Full-string wildcard matching for lowercase ASCII text.
proc wildcard_matching*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "wildcard_matching".} =
  if input == nil or length < 2 or length > 35: return -1
  if input[0] < 0 or input[0] > 12 or input[1] < 0 or input[1] > 20: return -1
  let textLength = int(input[0])
  let patternLength = int(input[1])
  if int(length) != 2 + textLength + patternLength: return -1
  for i in 0 ..< textLength:
    if input[2 + i] < 97 or input[2 + i] > 122: return -1
  let patternStart = 2 + textLength
  for j in 0 ..< patternLength:
    let token = input[patternStart + j]
    if not ((token >= 97 and token <= 122) or token == 42 or token == 63): return -1

  var dp: array[13, array[21, bool]]
  dp[0][0] = true
  for j in 1 .. patternLength:
    if input[patternStart + j - 1] == 42: dp[0][j] = dp[0][j - 1]
  for i in 1 .. textLength:
    for j in 1 .. patternLength:
      let token = input[patternStart + j - 1]
      if token == input[1 + i] or token == 63:
        dp[i][j] = dp[i - 1][j - 1]
      elif token == 42:
        dp[i][j] = dp[i - 1][j] or dp[i][j - 1]
  return int64(dp[textLength][patternLength])
