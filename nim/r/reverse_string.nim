proc reverse_string*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "reverse_string".} =
  if input.isNil or length < 1 or input[0] < 0 or input[0] > 256: return -1
  let n = int(input[0])
  if length != csize_t(n + 1): return -1
  for i in 0 ..< n:
    if input[i + 1] < 33 or input[i + 1] > 126: return -1
  if output.isNil or outputCapacity < csize_t(n + 1): return -2
  for i in 0 ..< n:
    output[i] = uint8(input[n - i])
  output[n] = 0
  int64(n)
