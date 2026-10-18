const MaxInputLength = 66
const MaxTextLength = 64
const MaxOutputBytes = 1536

proc putI64Le(output: var array[MaxOutputBytes, uint8], offset: int, value: int64) =
  let bits = uint64(value)
  for byteIndex in 0 ..< 8:
    output[offset + byteIndex] = uint8((bits shr (byteIndex * 8)) and 0xff'u64)

proc lz77_java_compress*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "lz77_java_compress".} =
  if input == nil or inputLength < 1 or inputLength > MaxInputLength.csize_t: return -1
  if input[0] < 0 or input[0] > MaxTextLength.int64: return -1
  let textLength = int(input[0])
  if inputLength != csize_t(1 + textLength): return -1
  for index in 0 ..< textLength:
    if input[index + 1] < 32 or input[index + 1] > 126: return -1

  var staged: array[MaxOutputBytes, uint8]
  var tokenCount = 0
  var current = 0
  while current < textLength:
    var bestDistance = 0
    var bestLength = 0
    let searchStart = max(0, current - 4096)
    let lookaheadEnd = min(current + 16, textLength)
    for candidate in searchStart ..< current:
      var matchLength = 0
      while current + matchLength < lookaheadEnd:
        var source = candidate + matchLength
        if source >= current:
          let distance = current - candidate
          source = candidate + (matchLength mod distance)
        if input[source + 1] != input[current + matchLength + 1]: break
        inc matchLength
      if matchLength > bestLength:
        bestDistance = current - candidate
        bestLength = matchLength

    let nextCharacter = if current + bestLength < textLength: input[current + bestLength + 1] else: 0'i64
    let byteOffset = tokenCount * 24
    putI64Le(staged, byteOffset, int64(bestDistance))
    putI64Le(staged, byteOffset + 8, int64(bestLength))
    putI64Le(staged, byteOffset + 16, nextCharacter)
    inc tokenCount
    current += if nextCharacter == 0: bestLength else: bestLength + 1

  let outputBytes = tokenCount * 24
  if outputBytes > MaxOutputBytes: return -1
  if output == nil or capacity < csize_t(outputBytes): return -2
  for index in 0 ..< outputBytes: output[index] = staged[index]
  int64(outputBytes)
