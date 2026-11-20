proc apostolico_crochemore_search*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "apostolico_crochemore_search".} =
  if input == nil or length < 2 or length > 4227: return -1
  if input[0] < 0 or input[0] > 4096 or input[1] < 1 or input[1] > 128: return -1
  let textLength = int(input[0])
  let patternLength = int(input[1])
  let patternStart = 2 + textLength
  if length != csize_t(2 + textLength + patternLength): return -1
  for index in 2..<int(length):
    if input[index] < 0 or input[index] > 3: return -1

  var kmpNext: array[129, int]
  kmpNext[0] = -1
  var preprocessIndex = 0
  var border = -1
  while preprocessIndex < patternLength:
    while border > -1 and input[patternStart + preprocessIndex] != input[patternStart + border]:
      border = kmpNext[border]
    inc preprocessIndex
    inc border
    if preprocessIndex < patternLength and input[patternStart + preprocessIndex] == input[patternStart + border]:
      kmpNext[preprocessIndex] = kmpNext[border]
    else:
      kmpNext[preprocessIndex] = border

  var ell = 1
  while ell < patternLength and input[patternStart + ell - 1] == input[patternStart + ell]:
    inc ell
  if ell == patternLength: ell = 0

  var i = ell
  var j = 0
  var k = 0
  var matchCount = 0'i64
  var sumOffsets = 0'i64
  var xorOffsets = 0'i64
  while j <= textLength - patternLength:
    while i < patternLength and input[patternStart + i] == input[2 + j + i]:
      inc i
    if i >= patternLength:
      while k < ell and input[patternStart + k] == input[2 + j + k]:
        inc k
      if k >= ell:
        inc matchCount
        sumOffsets += int64(j)
        xorOffsets = xorOffsets xor int64(j)

    j += i - kmpNext[i]
    if i == ell:
      if k > 0: dec k
    elif kmpNext[i] <= ell:
      k = kmpNext[i]
      if k < 0: k = 0
      i = ell
    else:
      k = ell
      i = kmpNext[i]

  return matchCount * 68_719_476_736'i64 + sumOffsets * 4096'i64 + xorOffsets
