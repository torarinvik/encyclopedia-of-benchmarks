const MaxTextLength = 32
const MaxInputLength = 34
const MaxAlphabet = 256

proc induce(symbols: seq[int32], upper: int, isS: seq[bool],
            sumS, sumL: array[MaxAlphabet + 2, int],
            orderedLms: seq[int]): seq[int] =
  let n = symbols.len
  result = newSeq[int](n)
  for i in 0 ..< n: result[i] = -1
  var bucket = sumS
  for position in orderedLms:
    let symbol = int(symbols[position])
    result[bucket[symbol]] = position
    inc bucket[symbol]
  bucket = sumL
  for i in 0 ..< n:
    let position = result[i]
    if position > 0 and not isS[position - 1]:
      let symbol = int(symbols[position - 1])
      result[bucket[symbol]] = position - 1
      inc bucket[symbol]
  bucket = sumL
  for i in countdown(n - 1, 0):
    let position = result[i]
    if position > 0 and isS[position - 1]:
      let symbol = int(symbols[position - 1]) + 1
      dec bucket[symbol]
      result[bucket[symbol]] = position - 1

proc sameLmsSubstring(symbols: seq[int32], isS: seq[bool],
                      lmsMap: seq[int], left, right: int): bool =
  if left == right: return true
  for offset in 0 ..< symbols.len:
    let a = left + offset
    let b = right + offset
    if a >= symbols.len or b >= symbols.len or symbols[a] != symbols[b] or isS[a] != isS[b]:
      return false
    let aLms = offset > 0 and lmsMap[a] >= 0
    let bLms = offset > 0 and lmsMap[b] >= 0
    if aLms or bLms: return aLms and bLms
  false

proc sais(symbols: seq[int32], upper: int): seq[int] =
  let n = symbols.len
  if n == 0: return @[]
  if n <= 2:
    result = newSeq[int](n)
    for i in 0 ..< n: result[i] = i
    if n == 2 and symbols[0] >= symbols[1]: swap(result[0], result[1])
    return

  var isS = newSeq[bool](n)
  isS[n - 1] = true
  for i in countdown(n - 2, 0):
    isS[i] = symbols[i] < symbols[i + 1] or (symbols[i] == symbols[i + 1] and isS[i + 1])

  var lmsMap = newSeq[int](n + 1)
  for i in 0 .. n: lmsMap[i] = -1
  var lms: seq[int] = @[]
  for i in 1 ..< n:
    if not isS[i - 1] and isS[i]:
      lmsMap[i] = lms.len
      lms.add(i)

  var sumS: array[MaxAlphabet + 2, int]
  var sumL: array[MaxAlphabet + 2, int]
  for i in 0 ..< n:
    let symbol = int(symbols[i])
    if isS[i]: inc sumL[symbol + 1]
    else: inc sumS[symbol]
  for symbol in 0 .. upper:
    sumS[symbol] += sumL[symbol]
    sumL[symbol + 1] += sumS[symbol]

  let suffixes = induce(symbols, upper, isS, sumS, sumL, lms)
  var sortedLms: seq[int] = @[]
  for position in suffixes:
    if position >= 0 and lmsMap[position] >= 0: sortedLms.add(position)
  var reduced = newSeq[int32](lms.len)
  var reducedUpper = 0
  for i in 0 ..< sortedLms.len:
    if i > 0 and not sameLmsSubstring(symbols, isS, lmsMap, sortedLms[i - 1], sortedLms[i]):
      inc reducedUpper
    reduced[lmsMap[sortedLms[i]]] = int32(reducedUpper)

  var reducedOrder: seq[int]
  if reducedUpper + 1 == reduced.len:
    reducedOrder = newSeq[int](reduced.len)
    for i, name in reduced: reducedOrder[int(name)] = i
  else:
    reducedOrder = sais(reduced, reducedUpper)
  var orderedLms = newSeq[int](reducedOrder.len)
  for i, index in reducedOrder: orderedLms[i] = lms[index]
  result = induce(symbols, upper, isS, sumS, sumL, orderedLms)

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = uint64(value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255)

proc suffix_array_sais*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "suffix_array_sais".} =
  if values == nil or length < 1 or length > csize_t(MaxInputLength): return -1
  let countValue = values[0]
  if countValue < 0 or countValue > int64(MaxTextLength): return -1
  let count = int(countValue)
  if length != csize_t(count + 1): return -1
  for i in 0 ..< count:
    if values[i + 1] < 0 or values[i + 1] > 255: return -1
  let outputBytes = count * 8
  if output == nil or outputCapacity < csize_t(outputBytes): return -2
  var symbols = newSeq[int32](count + 1)
  for i in 0 ..< count: symbols[i] = int32(values[i + 1] + 1)
  symbols[count] = 0
  let suffixes = sais(symbols, MaxAlphabet)
  var outIndex = 0
  for position in suffixes:
    if position == count: continue
    storeI64Le(output, outIndex * 8, int64(position))
    inc outIndex
  int64(outputBytes)
