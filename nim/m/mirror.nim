const
  MaxLength = 256
  MaxInputLength = MaxLength + 1

proc mirror*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "mirror".} =
  if input.isNil or length < 1 or length > MaxInputLength.csize_t: return -1
  if input[0] < 0 or input[0] > MaxLength: return -1
  let n = int(input[0])
  if length != csize_t(n + 1): return -1
  for i in 0 ..< n:
    if input[i + 1] < 1 or input[i + 1] > 127: return -1
  if output.isNil or capacity < csize_t(n + 1): return -2
  var buffer: array[MaxInputLength, uint8]
  for i in 0 ..< n: buffer[i] = uint8(input[i + 1])
  buffer[n] = 0
  var logicalLength = 0
  while buffer[logicalLength] != 0'u8: inc logicalLength
  if logicalLength > 0:
    var left = 0
    var right = logicalLength - 1
    while left <= right:
      swap(buffer[left], buffer[right])
      inc left
      if right == 0: break
      dec right
  for i in 0 ..< n: output[i] = buffer[i]
  output[n] = 0
  int64(n)
