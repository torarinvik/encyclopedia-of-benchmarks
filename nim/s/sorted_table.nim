const MaxParseableInputLength = 899
const MaxInitialKeys = 128
const MaxOperations = 256
const MaxSize = 256
const MinKey = -1_000_000'i64
const MaxKey = 1_000_000'i64
const KeyOffset = 1_000_001'i64
const HashModulus = 1_000_000_007'i64
const InvalidResult = -1'i64

proc lowerBound(values: var array[MaxSize, int64], size: int, target: int64): int =
  var left = 0
  var right = size
  while left < right:
    let middle = left + (right - left) div 2
    if values[middle] < target: left = middle + 1
    else: right = middle
  left

proc upperBound(values: var array[MaxSize, int64], size: int, target: int64): int =
  var left = 0
  var right = size
  while left < right:
    let middle = left + (right - left) div 2
    if values[middle] <= target: left = middle + 1
    else: right = middle
  left

proc keyCode(key: int64): int64 = key + KeyOffset

proc sequenceCode(values: var array[MaxSize, int64], first, last: int, descending: bool): int64 =
  let count = last - first
  var rollingHash = 0'i64
  if descending:
    var index = last
    while index > first:
      dec index
      rollingHash = (31 * rollingHash + keyCode(values[index])) mod HashModulus
  else:
    for index in first ..< last:
      rollingHash = (31 * rollingHash + keyCode(values[index])) mod HashModulus
  int64(count) * HashModulus + rollingHash

proc sorted_table_benchmark*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "sorted_table_benchmark".} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxParseableInputLength):
    return InvalidResult
  let initialCountValue = input[0]
  if initialCountValue < 0 or initialCountValue > int64(MaxInitialKeys): return InvalidResult
  let initialCount = int(initialCountValue)
  let operationCountIndex = initialCount + 1
  if operationCountIndex >= int(length): return InvalidResult
  let operationCountValue = input[operationCountIndex]
  if operationCountValue < 0 or operationCountValue > int64(MaxOperations): return InvalidResult
  let operationCount = int(operationCountValue)
  let operationsStart = operationCountIndex + 1
  if int(length) != operationsStart + 3 * operationCount: return InvalidResult

  var items: array[MaxSize, int64]
  for index in 0 ..< initialCount:
    let key = input[index + 1]
    if key < MinKey or key > MaxKey or (index > 0 and items[index - 1] >= key): return InvalidResult
    items[index] = key
  var size = initialCount
  var checksum = 0'i64

  for operation in 0 ..< operationCount:
    let offset = operationsStart + 3 * operation
    let opcode = input[offset]
    let a = input[offset + 1]
    let b = input[offset + 2]
    var hasObservation = true
    var observed = 0'i64
    var position = 0

    if opcode == 0 or opcode == 1 or opcode == 4 or opcode == 5 or opcode == 7:
      if b != 0 or a < MinKey or a > MaxKey: return InvalidResult
      position = lowerBound(items, size, a)
      let found = position < size and items[position] == a
      if opcode == 0:
        if found: observed = keyCode(a)
      elif opcode == 1:
        if found: observed = 1
      elif opcode == 4:
        if found: inc position
        if position < size: observed = keyCode(items[position])
      elif opcode == 5:
        if position > 0: observed = keyCode(items[position - 1])
      elif found:
        observed = keyCode(a)
        for index in position ..< size - 1: items[index] = items[index + 1]
        dec size
    elif opcode == 2 or opcode == 3:
      if a != 0 or b != 0: return InvalidResult
      if size > 0:
        observed = keyCode(items[if opcode == 2: 0 else: size - 1])
    elif opcode == 6:
      if a < MinKey or a > MaxKey or (b != 0 and b != 1): return InvalidResult
      position = lowerBound(items, size, a)
      let found = position < size and items[position] == a
      if found:
        observed = keyCode(a)
      else:
        if size >= MaxSize: return InvalidResult
        var index = size
        while index > position:
          items[index] = items[index - 1]
          dec index
        items[position] = a
        inc size
    elif opcode == 8 or opcode == 9:
      if a < MinKey or a > MaxKey or b < MinKey or b > MaxKey: return InvalidResult
      if a <= b:
        let first = lowerBound(items, size, a)
        let last = upperBound(items, size, b)
        observed = sequenceCode(items, first, last, opcode == 9)
    elif opcode == 10 or opcode == 11:
      if a != 0 or b != 0: return InvalidResult
      observed = sequenceCode(items, 0, size, opcode == 11)
    elif opcode == 12:
      if a != 0 or b != 0: return InvalidResult
      if size == 0: observed = 1
    elif opcode == 13:
      if a != 0 or b != 0: return InvalidResult
      size = 0
      hasObservation = false
    else:
      return InvalidResult

    if hasObservation:
      checksum += int64(operation + 1) * (observed + 1)

  for index in 0 ..< size:
    checksum += int64(operationCount + index + 1) * keyCode(items[index])
  checksum
