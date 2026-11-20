const MaxText = 4096
const MaxPattern = 128
const MaxInput = 4227
const Alphabet = 4

proc maximalShiftMatchShift(pattern: openArray[uint8], orderLoc, orderSymbol: openArray[int],
    m, prefixLength, initialShift: int): int =
  result = initialShift
  while result < m:
    var orderIndex = prefixLength - 1
    while orderIndex >= 0:
      let patternIndex = orderLoc[orderIndex] - result
      if patternIndex >= 0 and orderSymbol[orderIndex] != int(pattern[patternIndex]): break
      dec orderIndex
    if orderIndex < 0: break
    inc result

proc maximal_shift_search*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "maximal_shift_search".} =
  if input == nil or length < 2 or length > csize_t(MaxInput): return -1
  let n64 = input[0]
  let m64 = input[1]
  if n64 < 0 or n64 > int64(MaxText) or m64 < 1 or m64 > int64(MaxPattern): return -1
  let n = int(n64)
  let m = int(m64)
  if length != csize_t(2 + n + m): return -1
  var text: array[MaxText, uint8]
  var pattern: array[MaxPattern, uint8]
  for q in 0 ..< n:
    let value = input[2 + q]
    if value < 0 or value >= Alphabet: return -1
    text[q] = uint8(value)
  for q in 0 ..< m:
    let value = input[2 + n + q]
    if value < 0 or value >= Alphabet: return -1
    pattern[q] = uint8(value)
  if n < m: return 0

  var leadingShift: array[MaxPattern, int]
  var orderLoc: array[MaxPattern + 1, int]
  var orderSymbol: array[MaxPattern + 1, int]
  var quickShift: array[Alphabet, int]
  var adaptedShift: array[MaxPattern + 1, int]
  for i in 0 ..< m:
    var previous = i - 1
    while previous >= 0 and pattern[previous] != pattern[i]: dec previous
    leadingShift[i] = i - previous
    var position = i
    while position > 0:
      let priorLoc = orderLoc[position - 1]
      if leadingShift[priorLoc] > leadingShift[i] or
          (leadingShift[priorLoc] == leadingShift[i] and priorLoc > i): break
      orderLoc[position] = priorLoc
      dec position
    orderLoc[position] = i
  for i in 0 ..< m: orderSymbol[i] = int(pattern[orderLoc[i]])
  orderLoc[m] = m
  orderSymbol[m] = -1
  for symbol in 0 ..< Alphabet: quickShift[symbol] = m + 1
  for i in 0 ..< m: quickShift[int(pattern[i])] = m - i

  var shift = 1
  adaptedShift[0] = 1
  for prefixLength in 1 .. m:
    shift = maximalShiftMatchShift(pattern, orderLoc, orderSymbol, m, prefixLength, shift)
    adaptedShift[prefixLength] = shift
  for prefixLength in 0 .. m:
    shift = adaptedShift[prefixLength]
    while shift < m:
      let patternIndex = orderLoc[prefixLength] - shift
      if patternIndex < 0 or orderSymbol[prefixLength] != int(pattern[patternIndex]): break
      inc shift
      shift = maximalShiftMatchShift(pattern, orderLoc, orderSymbol, m, prefixLength, shift)
    adaptedShift[prefixLength] = shift

  var count = 0'i64
  var offsetSum = 0'i64
  var offsetXor = 0'i64
  var start = 0
  while start <= n - m:
    var compared = 0
    while compared < m and orderSymbol[compared] == int(text[start + orderLoc[compared]]): inc compared
    if compared == m:
      inc count
      offsetSum += int64(start)
      offsetXor = offsetXor xor int64(start)
    let lookahead = start + m
    if lookahead >= n: break
    start += max(adaptedShift[compared], quickShift[int(text[lookahead])])
  (count shl 36) or (offsetSum shl 12) or offsetXor
