const MaxTextLength = 16
const MaxInputLength = 18
const MaxOutputBytes = 128

proc symbolAt(symbols: ptr UncheckedArray[int64], length, position: int): int64 =
  if position < length: symbols[position] else: 0

proc sampleRank(ranks: ptr UncheckedArray[int64], length, position: int): int64 =
  if position < length: ranks[position] else: -1

proc tripleCompare(symbols: ptr UncheckedArray[int64], length, left, right: int): int =
  for offset in 0 ..< 3:
    let a = symbolAt(symbols, length, left + offset)
    let b = symbolAt(symbols, length, right + offset)
    if a != b: return (if a < b: -1 else: 1)
  0

proc suffixCompare(symbols: ptr UncheckedArray[int64], length: int,
                    leftStart, rightStart: int): int =
  var left = leftStart
  var right = rightStart
  while left < length and right < length:
    if symbols[left] != symbols[right]: return (if symbols[left] < symbols[right]: -1 else: 1)
    inc left
    inc right
  if left == length and right == length: return 0
  if left == length: -1 else: 1

proc zeroPairCompare(symbols, ranks: ptr UncheckedArray[int64], length, left, right: int): int =
  let leftSymbol = symbolAt(symbols, length, left)
  let rightSymbol = symbolAt(symbols, length, right)
  if leftSymbol != rightSymbol: return (if leftSymbol < rightSymbol: -1 else: 1)
  let leftRank = sampleRank(ranks, length, left + 1)
  let rightRank = sampleRank(ranks, length, right + 1)
  if leftRank != rightRank: return (if leftRank < rightRank: -1 else: 1)
  0

proc mergeCompare(symbols, ranks: ptr UncheckedArray[int64], length, zero, sample: int): int =
  let firstZero = symbolAt(symbols, length, zero)
  let firstSample = symbolAt(symbols, length, sample)
  if firstZero != firstSample: return (if firstZero < firstSample: -1 else: 1)
  if sample mod 3 == 1:
    let zeroRank = sampleRank(ranks, length, zero + 1)
    let sampleSuffixRank = sampleRank(ranks, length, sample + 1)
    if zeroRank != sampleSuffixRank: return (if zeroRank < sampleSuffixRank: -1 else: 1)
  else:
    let secondZero = symbolAt(symbols, length, zero + 1)
    let secondSample = symbolAt(symbols, length, sample + 1)
    if secondZero != secondSample: return (if secondZero < secondSample: -1 else: 1)
    let zeroRank = sampleRank(ranks, length, zero + 2)
    let sampleSuffixRank = sampleRank(ranks, length, sample + 2)
    if zeroRank != sampleSuffixRank: return (if zeroRank < sampleSuffixRank: -1 else: 1)
  0

proc dc3(symbols: ptr UncheckedArray[int64], length: int,
         suffixes: ptr UncheckedArray[int]) =
  if length == 0: return
  if length <= 3:
    for i in 0 ..< length: suffixes[i] = i
    for i in 1 ..< length:
      let key = suffixes[i]
      var position = i
      while position > 0 and suffixCompare(symbols, length, key, suffixes[position - 1]) < 0:
        suffixes[position] = suffixes[position - 1]
        dec position
      suffixes[position] = key
    return

  var samplePositions: array[MaxTextLength, int]
  var sampleCount = 0
  for i in 1 ..< length:
    if i mod 3 != 0:
      samplePositions[sampleCount] = i
      inc sampleCount
  for i in 1 ..< sampleCount:
    let key = samplePositions[i]
    var position = i
    while position > 0 and tripleCompare(symbols, length, key, samplePositions[position - 1]) < 0:
      samplePositions[position] = samplePositions[position - 1]
      dec position
    samplePositions[position] = key

  var tripleRanks: array[MaxTextLength, int64]
  var nextRank = 0'i64
  for i in 0 ..< sampleCount:
    if i == 0 or tripleCompare(symbols, length, samplePositions[i - 1], samplePositions[i]) != 0:
      inc nextRank
    tripleRanks[samplePositions[i]] = nextRank

  var groupOneCount = 0
  for i in countup(1, length - 1, 3): inc groupOneCount
  var reduced: array[MaxTextLength, int64]
  var reducedLength = 0
  for i in countup(1, length - 1, 3):
    reduced[reducedLength] = tripleRanks[i]
    inc reducedLength
  reduced[reducedLength] = 0
  inc reducedLength
  for i in countup(2, length - 1, 3):
    reduced[reducedLength] = tripleRanks[i]
    inc reducedLength
  var reducedOrder: array[MaxTextLength, int]
  dc3(addr reduced[0], reducedLength, addr reducedOrder[0])

  var sampleOrder: array[MaxTextLength, int]
  var ranks: array[MaxTextLength, int64]
  for i in 0 ..< length: ranks[i] = -1
  var sampleOrderCount = 0
  for i in 0 ..< reducedLength:
    let reducedPosition = reducedOrder[i]
    if reducedPosition == groupOneCount: continue
    let sourcePosition = if reducedPosition < groupOneCount:
      1 + 3 * reducedPosition
    else:
      2 + 3 * (reducedPosition - groupOneCount - 1)
    sampleOrder[sampleOrderCount] = sourcePosition
    ranks[sourcePosition] = int64(sampleOrderCount)
    inc sampleOrderCount

  var zeroPositions: array[MaxTextLength, int]
  var zeroCount = 0
  for i in countup(0, length - 1, 3):
    zeroPositions[zeroCount] = i
    inc zeroCount
  for i in 1 ..< zeroCount:
    let key = zeroPositions[i]
    var position = i
    while position > 0 and zeroPairCompare(symbols, addr ranks[0], length, key, zeroPositions[position - 1]) < 0:
      zeroPositions[position] = zeroPositions[position - 1]
      dec position
    zeroPositions[position] = key

  var zeroIndex = 0
  var sampleIndex = 0
  var outputIndex = 0
  while zeroIndex < zeroCount and sampleIndex < sampleOrderCount:
    let zero = zeroPositions[zeroIndex]
    let sample = sampleOrder[sampleIndex]
    if mergeCompare(symbols, addr ranks[0], length, zero, sample) < 0:
      suffixes[outputIndex] = zero
      inc zeroIndex
    else:
      suffixes[outputIndex] = sample
      inc sampleIndex
    inc outputIndex
  while zeroIndex < zeroCount:
    suffixes[outputIndex] = zeroPositions[zeroIndex]
    inc zeroIndex
    inc outputIndex
  while sampleIndex < sampleOrderCount:
    suffixes[outputIndex] = sampleOrder[sampleIndex]
    inc sampleIndex
    inc outputIndex

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255)

proc suffix_array_dc3*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "suffix_array_dc3".} =
  if values == nil or length < 1 or length > csize_t(MaxInputLength): return -1
  let countValue = values[0]
  if countValue < 0 or countValue > int64(MaxTextLength): return -1
  let count = int(countValue)
  if length != csize_t(count + 1): return -1
  for i in 0 ..< count:
    if values[i + 1] < 0 or values[i + 1] > 255: return -1
  let outputBytes = count * 8
  if output == nil or outputCapacity < csize_t(outputBytes): return -2
  if count == 0: return 0
  var symbols: array[MaxTextLength, int64]
  for i in 0 ..< count: symbols[i] = values[i + 1] + 1
  var suffixes: array[MaxTextLength, int]
  dc3(addr symbols[0], count, addr suffixes[0])
  for i in 0 ..< count: storeI64Le(output, i * 8, int64(suffixes[i]))
  int64(outputBytes)
