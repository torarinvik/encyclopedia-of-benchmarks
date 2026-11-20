const MaxText = 255
const MaxPattern = 64
const MaxFrame = 322

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc smith_string_search*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "smith_string_search".} =
  if input.isNil or length < 2 or length > MaxFrame: return -1
  if input[0] < 0 or input[0] > MaxText or input[1] < 1 or input[1] > MaxPattern: return -1
  let n = int(input[0])
  let m = int(input[1])
  if int(length) != 2 + n + m: return -1
  for i in 0 ..< n + m:
    if input[2 + i] < 0 or input[2 + i] > 127: return -1

  var positions: array[MaxText, int64]
  var matchCount = 0
  if m <= n:
    let patternStart = 2 + n
    var horspool: array[128, int]
    var quickSearch: array[128, int]
    for byte in 0 ..< 128:
      horspool[byte] = m
      quickSearch[byte] = m + 1
    for i in 0 ..< m - 1: horspool[int(input[patternStart + i])] = m - i - 1
    for i in 0 ..< m: quickSearch[int(input[patternStart + i])] = m - i

    let lastAlignment = n - m
    var alignment = 0
    while alignment <= lastAlignment:
      var matches = true
      for i in 0 ..< m:
        if input[patternStart + i] != input[2 + alignment + i]:
          matches = false
          break
      if matches:
        positions[matchCount] = int64(alignment)
        inc matchCount
      let endByte = int(input[2 + alignment + m - 1])
      let lookahead = alignment + m
      var quickShift = m + 1
      if lookahead < n: quickShift = quickSearch[int(input[2 + lookahead])]
      let endShift = horspool[endByte]
      alignment += max(endShift, quickShift)

  let outputBytes = matchCount * 8
  if output.isNil or outputCapacity < csize_t(outputBytes): return -2
  for i in 0 ..< matchCount: storeI64Le(output, i * 8, positions[i])
  int64(outputBytes)
