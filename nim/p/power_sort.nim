const MaxValues = 64
const MaxInputValues = 67
const MinValue = -1_000_000'i64
const MaxValue = 1_000_000'i64

type RunEntry = object
  start: int
  length: int
  power: int64

proc keyLess(left, right: int64, reverse: bool): bool =
  if reverse: left > right else: left < right

proc findRun(values: var array[MaxValues, int64], start, end: int, reverse: bool): int =
  if start >= end - 1: return start + 1
  var runEnd = start + 1
  if keyLess(values[runEnd], values[start], reverse):
    while runEnd < end and keyLess(values[runEnd], values[runEnd - 1], reverse): inc runEnd
    var left = start
    var right = runEnd - 1
    while left < right:
      swap(values[left], values[right])
      inc left
      dec right
  else:
    while runEnd < end and not keyLess(values[runEnd], values[runEnd - 1], reverse): inc runEnd
  runEnd

proc nodePower(totalLength, b1, n1, b2, n2: int): int64 =
  let a = int64(2 * b1 + n1)
  let b = int64(2 * b2 + n2)
  let denominator = int64(2 * totalLength)
  var power = 0
  while (a * (1'i64 shl power)) div denominator == (b * (1'i64 shl power)) div denominator:
    inc power
  int64(power)

proc mergeRuns(values: var array[MaxValues, int64], start1, end1, end2: int, reverse: bool) =
  var left: array[MaxValues, int64]
  var right: array[MaxValues, int64]
  let leftLength = end1 - start1
  let rightLength = end2 - end1
  for index in 0 ..< leftLength: left[index] = values[start1 + index]
  for index in 0 ..< rightLength: right[index] = values[end1 + index]
  var i = 0
  var j = 0
  var output = start1
  while i < leftLength and j < rightLength:
    let takeLeft = if reverse: left[i] >= right[j] else: left[i] <= right[j]
    if takeLeft:
      values[output] = left[i]
      inc i
    else:
      values[output] = right[j]
      inc j
    inc output
  while i < leftLength:
    values[output] = left[i]
    inc i
    inc output
  while j < rightLength:
    values[output] = right[j]
    inc j
    inc output

proc powerSortImpl(values: var array[MaxValues, int64], length: int, reverse: bool) =
  if length <= 1: return
  var stack: array[MaxValues, RunEntry]
  var stackSize = 0
  var start = 0
  while start < length:
    let runEnd = findRun(values, start, length, reverse)
    var runLength = runEnd - start
    var power = if stackSize == 0: 0'i64 else:
      nodePower(length, stack[stackSize - 1].start, stack[stackSize - 1].length, start, runLength)
    while stackSize > 0 and stack[stackSize - 1].power >= power:
      dec stackSize
      let previous = stack[stackSize]
      mergeRuns(values, previous.start, previous.start + previous.length, runEnd, reverse)
      start = previous.start
      runLength = runEnd - start
      power = if stackSize == 0: 0'i64 else:
        nodePower(length, stack[stackSize - 1].start, stack[stackSize - 1].length, start, runLength)
    stack[stackSize] = RunEntry(start: start, length: runLength, power: power)
    inc stackSize
    start = runEnd
  while stackSize > 1:
    dec stackSize
    let right = stack[stackSize]
    dec stackSize
    let left = stack[stackSize]
    let mergedEnd = right.start + right.length
    mergeRuns(values, left.start, left.start + left.length, mergedEnd, reverse)
    let mergedLength = mergedEnd - left.start
    let power = if stackSize == 0: 0'i64 else:
      nodePower(length, stack[stackSize - 1].start, stack[stackSize - 1].length, left.start, mergedLength)
    stack[stackSize] = RunEntry(start: left.start, length: mergedLength, power: power)
    inc stackSize

proc writeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)

proc power_sort*(input: ptr UncheckedArray[int64], length: csize_t,
                 output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "power_sort".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputValues): return -1
  let reverseValue = input[0]
  let countValue = input[1]
  if (reverseValue != 0 and reverseValue != 1) or countValue < 0 or countValue > MaxValues.int64: return -1
  let count = int(countValue)
  if length != csize_t(2 + count): return -1
  var values: array[MaxValues, int64]
  for index in 0 ..< count:
    let value = input[2 + index]
    if value < MinValue or value > MaxValue: return -1
    values[index] = value
  if count == 0: return 0
  let outputBytes = csize_t(8 * count)
  if output.isNil or capacity < outputBytes: return -2
  powerSortImpl(values, count, reverseValue == 1)
  for index in 0 ..< count: writeI64Le(output, 8 * index, values[index])
  int64(outputBytes)
