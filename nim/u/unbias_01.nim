proc unbias_01*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "unbias_01".} =
  if length < 1 or length > 257: return -1
  let n = input[0]
  if n < 0 or n > 256 or length != csize_t(n + 1): return -1
  for i in 0 ..< int(n):
    if input[i + 1] != 0 and input[i + 1] != 1: return -1
  var i = 0
  while i + 1 < int(n):
    if input[i + 1] != input[i + 2]: return input[i + 1]
    i += 2
  -1
