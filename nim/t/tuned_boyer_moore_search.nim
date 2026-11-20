const MaxText = 255
const MaxPattern = 64
const MaxFrame = 322
const MaxPadded = MaxText + MaxPattern

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc tuned_boyer_moore_search*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "tuned_boyer_moore_search".} =
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
    var padded: array[MaxPadded, uint8]
    var shifts: array[128, int]
    let patternStart = 2 + n
    let finalByte = uint8(input[patternStart + m - 1])
    for i in 0 ..< n: padded[i] = uint8(input[2 + i])
    for i in 0 ..< m: padded[n + i] = finalByte
    for byte in 0 ..< 128: shifts[byte] = m
    for i in 0 ..< m - 1: shifts[int(input[patternStart + i])] = m - i - 1
    let finalShift = shifts[int(finalByte)]
    shifts[int(finalByte)] = 0
    var alignment = 0
    while alignment < n:
      var skip = shifts[int(padded[alignment + m - 1])]
      while skip != 0:
        alignment += skip
        skip = shifts[int(padded[alignment + m - 1])]
        alignment += skip
        skip = shifts[int(padded[alignment + m - 1])]
        alignment += skip
        skip = shifts[int(padded[alignment + m - 1])]
      var prefixMatches = true
      for i in 0 ..< m - 1:
        if uint8(input[patternStart + i]) != padded[alignment + i]:
          prefixMatches = false
          break
      if prefixMatches and alignment < n:
        positions[matchCount] = int64(alignment)
        inc matchCount
      alignment += finalShift

  let outputBytes = matchCount * 8
  if output.isNil or outputCapacity < csize_t(outputBytes): return -2
  for i in 0 ..< matchCount: storeI64Le(output, i * 8, positions[i])
  int64(outputBytes)
