proc reverse_letters*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "reverse_letters".} =
  if input.isNil or length < 1 or input[0] < 0 or input[0] > 256: return -1
  let n = int(input[0])
  if length != csize_t(n + 1): return -1
  for i in 0 ..< n:
    if input[i + 1] == 32:
      if i == 0 or i + 1 == n or input[i] == 32: return -1
    elif input[i + 1] < 33 or input[i + 1] > 126: return -1
  if output.isNil or outputCapacity < csize_t(n + 1): return -2
  var start = 0
  while start < n:
    var ending = start
    while ending < n and input[ending + 1] != 32: inc ending
    for i in 0 ..< ending - start + 1:
      output[start + i] = uint8(input[ending - i])
    if ending < n: output[ending] = 32
    start = ending + 1
  output[n] = 0
  int64(n)
