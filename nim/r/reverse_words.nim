proc reverse_words*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "reverse_words".} =
  if input.isNil or length < 1 or input[0] < 0 or input[0] > 256: return -1
  let n = int(input[0])
  if length != csize_t(n + 1): return -1
  for i in 0 ..< n:
    let b = input[i + 1]
    if not (b == 32 or (b >= 33 and b <= 126)): return -1
    if b == 32 and (i == 0 or i + 1 == n or input[i] == 32): return -1
  if output.isNil or outputCapacity < csize_t(n + 1): return -2
  var written = 0
  var ending = n
  while ending > 0:
    var start = ending
    while start > 0 and input[start] != 32: dec start
    let wordStart = start
    for i in wordStart ..< ending:
      output[written] = uint8(input[i + 1]); inc written
    if wordStart == 0: break
    output[written] = 32; inc written
    ending = start - 1
  output[written] = 0
  int64(written)
