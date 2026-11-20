const MaxTextLength = 32
const MaxInputLength = 34
const MaxTrieNodes = 33
const MaxTokens = 32
const MaxOutputBytes = 776

proc putI64Le(output: var array[MaxOutputBytes, uint8], offset: int, value: int64) =
  let bits = uint64(value)
  for byteIndex in 0 ..< 8:
    output[offset + byteIndex] = uint8((bits shr (byteIndex * 8)) and 0xff'u64)

proc lz78_run_length_transform*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "lz78_run_length_transform".} =
  if input == nil or inputLength < 1 or inputLength > MaxInputLength.csize_t: return -1
  if input[0] < 0 or input[0] > MaxTextLength: return -1
  let n = int(input[0])
  if inputLength != csize_t(n + 1): return -1
  for i in 0 ..< n:
    if input[csize_t(i + 1)] < 1 or input[csize_t(i + 1)] > 3: return -1

  var transformed: array[MaxTextLength, int64]
  var transformedLength = 0
  var position = 0
  while position < n:
    let symbol = input[csize_t(position + 1)]
    var end = position + 1
    while end < n and input[csize_t(end + 1)] == symbol: inc end
    let runLength = end - position
    var highestBit = 0
    var value = runLength
    while value > 1:
      value = value shr 1
      inc highestBit
    for bit in countdown(highestBit, 0):
      transformed[transformedLength] = if ((runLength shr bit) and 1) == 1: symbol else: 0
      inc transformedLength
    position = end

  var children: array[MaxTrieNodes, array[4, int]]
  var tokens: array[MaxTokens, array[3, int64]]
  var tokenCount = 0
  var textPosition = 0
  var nextPhraseId = 1
  while textPosition < transformedLength:
    var node = 0
    var end = textPosition
    while end < transformedLength:
      let child = children[node][int(transformed[end])]
      if child == 0: break
      node = child
      inc end
    if end == transformedLength:
      if node != 0:
        tokens[tokenCount] = [int64(node), 0'i64, 1'i64]
        inc tokenCount
      break
    let symbol = int(transformed[end])
    tokens[tokenCount] = [int64(node), int64(symbol), 0'i64]
    inc tokenCount
    children[node][symbol] = nextPhraseId
    inc nextPhraseId
    textPosition = end + 1

  let outputBytes = 8 + 24 * tokenCount
  var staged: array[MaxOutputBytes, uint8]
  putI64Le(staged, 0, int64(tokenCount))
  for token in 0 ..< tokenCount:
    for field in 0 ..< 3:
      putI64Le(staged, 8 + 24 * token + 8 * field, tokens[token][field])
  if output == nil or capacity < csize_t(outputBytes): return -2
  for i in 0 ..< outputBytes: output[i] = staged[i]
  int64(outputBytes)
