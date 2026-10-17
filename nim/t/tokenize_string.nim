proc tokenize_string*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "tokenize_string".} =
  if input.isNil or length < 2 or length > 130: return -1
  if input[0] < 0 or input[0] > 128: return -1
  let textLength = int(input[0])
  if int(length) != textLength + 2: return -1
  let separator = input[1]
  if separator != 44 and separator != 46 and separator != 58: return -1
  var separatorCount = 0
  for index in 0..<textLength:
    let byte = input[index + 2]
    if byte < 32 or byte > 126: return -1
    if byte == separator: inc separatorCount
  if separatorCount > 18: return -1
  let outputLength = textLength + 2
  if output.isNil or capacity < csize_t(outputLength): return -2
  output[0] = uint8(separatorCount + 1)
  for index in 0..<textLength:
    let byte = input[index + 2]
    output[index + 1] = if byte == separator: 0'u8 else: uint8(byte)
  output[outputLength - 1] = 0
  int64(outputLength)
