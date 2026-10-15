proc title_case_conversion*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "title_case_conversion".} =
  if input.isNil or length < 1 or input[0] < 0 or input[0] > 256: return -1
  let n = int(input[0])
  if length != csize_t(n + 1): return -1
  for i in 0 ..< n:
    let value = input[i + 1]
    if (value >= 65 and value <= 90) or (value >= 97 and value <= 122):
      continue
    if value == 32 and i > 0 and i + 1 < n and input[i] != 32:
      continue
    return -1
  if output.isNil or outputCapacity < csize_t(n + 1): return -2
  var atWordStart = true
  for i in 0 ..< n:
    var value = input[i + 1]
    if value == 32:
      output[i] = 32
      atWordStart = true
    elif atWordStart:
      if value >= 97 and value <= 122: value -= 32
      output[i] = uint8(value)
      atWordStart = false
    else:
      if value >= 65 and value <= 90: value += 32
      output[i] = uint8(value)
  output[n] = 0
  int64(n)
