const MaxTextLength = 4096
const MaxPatternLength = 128
const MaxInputLength = 4227

proc preprocess(pattern: array[MaxPatternLength + 1, uint8], patternLength: int,
    h, nextTable, shift: var array[MaxPatternLength + 1, int]): int =
  var hmax: array[MaxPatternLength + 2, int]
  var kmin, rmin, nhd0: array[MaxPatternLength + 1, int]

  var i = 1
  var k = 1
  while true:
    while pattern[i] == pattern[i - k]: inc i
    hmax[k] = i
    var q = k + 1
    while hmax[q - k] + k < i:
      hmax[q] = hmax[q - k] + k
      inc q
    k = q
    if k == i + 1: i = k
    if k > patternLength: break

  i = patternLength
  while i >= 1:
    if hmax[i] < patternLength: kmin[hmax[i]] = i
    dec i

  var r = patternLength
  i = patternLength - 1
  while i >= 0:
    if hmax[i + 1] == patternLength: r = i + 1
    if kmin[i] == 0: rmin[i] = r else: rmin[i] = 0
    dec i

  var noholeLast = -1
  var holeAt = patternLength
  for position in 0 ..< patternLength:
    if kmin[position] == 0:
      dec holeAt
      h[holeAt] = position
    else:
      inc noholeLast
      h[noholeLast] = position
  let nd = noholeLast

  i = 0
  while i <= nd:
    shift[i] = kmin[h[i]]
    inc i
  i = nd + 1
  while i < patternLength:
    shift[i] = rmin[h[i]]
    inc i
  shift[patternLength] = rmin[0]

  var noholeCount = 0
  for position in 0 ..< patternLength:
    nhd0[position] = noholeCount
    if kmin[position] > 0: inc noholeCount

  i = 0
  while i <= nd:
    nextTable[i] = nhd0[h[i] - kmin[h[i]]]
    inc i
  i = nd + 1
  while i < patternLength:
    nextTable[i] = nhd0[patternLength - rmin[h[i]]]
    inc i
  nextTable[patternLength] = nhd0[patternLength - rmin[h[patternLength - 1]]]
  nd

proc colussi_search*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "colussi_search".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputLength): return -1
  let textLength64 = input[0]
  let patternLength64 = input[1]
  if textLength64 < 0 or textLength64 > int64(MaxTextLength) or
      patternLength64 < 1 or patternLength64 > int64(MaxPatternLength): return -1
  let textLength = int(textLength64)
  let patternLength = int(patternLength64)
  if length != csize_t(2 + textLength + patternLength): return -1

  var text: array[MaxTextLength, uint8]
  var pattern: array[MaxPatternLength + 1, uint8]
  for i in 0 ..< textLength:
    let symbol = input[2 + i]
    if symbol < 0 or symbol > 3: return -1
    text[i] = uint8(symbol)
  let patternOffset = 2 + textLength
  for i in 0 ..< patternLength:
    let symbol = input[patternOffset + i]
    if symbol < 0 or symbol > 3: return -1
    pattern[i] = uint8(symbol)
  pattern[patternLength] = 4
  if textLength < patternLength: return 0

  var h, nextTable, shift: array[MaxPatternLength + 1, int]
  let nd = preprocess(pattern, patternLength, h, nextTable, shift)
  var i = 0
  var j = 0
  var last = -1
  var matchCount = 0'i64
  var offsetSum = 0'i64
  var offsetXor = 0'i64
  while j <= textLength - patternLength:
    while i < patternLength and last < j + h[i] and pattern[h[i]] == text[j + h[i]]: inc i
    if i >= patternLength or last >= j + h[i]:
      inc matchCount
      offsetSum += int64(j)
      offsetXor = offsetXor xor int64(j)
      i = patternLength
    if i > nd: last = j + patternLength - 1
    j += shift[i]
    i = nextTable[i]
  (matchCount shl 36) or (offsetSum shl 12) or offsetXor
