const
  MaxText = 256
  MaxInput = MaxText + 2
proc split*(input: ptr UncheckedArray[int64], length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "split".} =
  if input.isNil or length < 2 or length > csize_t(MaxInput + 1): return -1
  if input[0] < 0 or input[0] > MaxText or input[1] < 0 or input[1] > 127: return -1
  let n = int(input[0])
  if length != csize_t(n + 2): return -1
  for i in 0 ..< n:
    if input[i + 2] < 0 or input[i + 2] > 127: return -1
  if n > 0 and input[n + 1] == input[1]: return -1
  var separators = 0
  for i in 0 ..< n:
    if input[i + 2] == input[1]: inc separators
  if n > 0 and separators == 0: return -1
  let count = separators + 1
  let required = 2 + 2 * count + n - separators
  if output.isNil or capacity < csize_t(required): return -2
  output[0] = uint8(count); output[1] = uint8(count shr 8)
  var pos = 2; var start = 0
  for i in 0 .. n:
    if i == n or input[i + 2] == input[1]:
      let field = i - start
      output[pos] = uint8(field); output[pos + 1] = uint8(field shr 8); pos += 2
      for j in start ..< i: output[pos] = uint8(input[j + 2]); inc pos
      start = i + 1
  int64(required)
