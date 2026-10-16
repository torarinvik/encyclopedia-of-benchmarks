proc jump_game*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "jump_game".} =
  if input.isNil or length < 2 or length > 1025 or input[0] < 1 or input[0] > 1024 or length != csize_t(input[0] + 1): return -2
  let n = int(input[0])
  for i in 0 ..< n:
    if input[i + 1] < 0 or input[i + 1] > 1000000: return -2
  var lastPos = n - 1
  for i in countdown(n - 1, 0):
    if i + int(input[i + 1]) >= lastPos: lastPos = i
  if lastPos == 0: 1 else: 0
