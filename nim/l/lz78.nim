const MaxInputLength = 66
const MaxTextLength = 64
const MaxOutputBytes = 1024

proc putI64Le(output: var array[MaxOutputBytes, uint8], offset: int, value: int64) =
  let bits = uint64(value)
  for byteIndex in 0 ..< 8:
    output[offset + byteIndex] = uint8((bits shr (byteIndex * 8)) and 0xff'u64)

proc lz78_compress*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "lz78_compress".} =
  if input == nil or inputLength < 1 or inputLength > MaxInputLength.csize_t: return -1
  if input[0] < 0 or input[0] > MaxTextLength: return -1
  let textLength = int(input[0])
  if inputLength != csize_t(1 + textLength): return -1
  for index in 0 ..< textLength:
    if input[csize_t(index + 1)] < 32 or input[csize_t(index + 1)] > 126: return -1

  var edgeParent: array[MaxTextLength, int64]
  var edgeCharacter: array[MaxTextLength, int64]
  var dictionarySize = 0
  var tokenIndices: array[MaxTextLength, int64]
  var tokenCharacters: array[MaxTextLength, int64]
  var tokenCount = 0
  var currentIndex = 0'i64
  for index in 0 ..< textLength:
    let character = input[csize_t(index + 1)]
    var found = -1
    for edge in 0 ..< dictionarySize:
      if edgeParent[edge] == currentIndex and edgeCharacter[edge] == character:
        found = edge
        break
    if found >= 0:
      currentIndex = int64(found + 1)
    else:
      tokenIndices[tokenCount] = currentIndex
      tokenCharacters[tokenCount] = character
      tokenCount += 1
      edgeParent[dictionarySize] = currentIndex
      edgeCharacter[dictionarySize] = character
      dictionarySize += 1
      currentIndex = 0
  if currentIndex != 0:
    tokenIndices[tokenCount] = currentIndex
    tokenCharacters[tokenCount] = 0
    tokenCount += 1

  let outputBytes = 16 * tokenCount
  var staged: array[MaxOutputBytes, uint8]
  for token in 0 ..< tokenCount:
    putI64Le(staged, 16 * token, tokenIndices[token])
    putI64Le(staged, 16 * token + 8, tokenCharacters[token])
  if output == nil or capacity < csize_t(outputBytes): return -2
  for index in 0 ..< outputBytes: output[index] = staged[index]
  int64(outputBytes)
