const MaxParseableInputLength = 1025
const MaxOperations = 512
const MaxSize = 256
const MaxValue = 1_000_000'i64
const ChecksumOffset = 1_000_000'i64
const InvalidResult = -1'i64

proc lowerBound(values: var array[MaxSize, int64], size: int, target: int64): int =
  var left = 0
  var right = size
  while left < right:
    let middle = left + (right - left) div 2
    if values[middle] < target: left = middle + 1
    else: right = middle
  left

proc sorted_list_benchmark*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "sorted_list_benchmark".} =
  if length > csize_t(MaxParseableInputLength) or (length > csize_t(0) and input.isNil) or
      (length mod csize_t(2) != csize_t(0)):
    return InvalidResult
  let operationCount = int(length div csize_t(2))
  if operationCount > MaxOperations: return InvalidResult

  var items: array[MaxSize, int64]
  var size = 0
  var checksum = 0'i64
  for operation in 0 ..< operationCount:
    let opcode = input[2 * operation]
    let payload = input[2 * operation + 1]
    var observed = 0'i64
    var hasObservation = true

    if opcode == 0:
      if payload < 0 or payload > MaxValue or size >= MaxSize: return InvalidResult
      let position = lowerBound(items, size, payload)
      var index = size
      while index > position:
        items[index] = items[index - 1]
        dec index
      items[position] = payload
      inc size
      hasObservation = false
    elif opcode == 1 or opcode == 2:
      if payload < 0 or payload > MaxValue: return InvalidResult
      let position = lowerBound(items, size, payload)
      let found = position < size and items[position] == payload
      if found: observed = 1
      if opcode == 2 and found:
        for index in position ..< size - 1:
          items[index] = items[index + 1]
        dec size
    elif opcode == 3:
      if payload != 0: return InvalidResult
      observed = int64(size)
    elif opcode == 4:
      if payload < 0 or payload >= int64(size): return InvalidResult
      observed = items[int(payload)]
    elif opcode == 5:
      if payload != 0: return InvalidResult
      size = 0
      hasObservation = false
    else:
      return InvalidResult

    if hasObservation:
      checksum += int64(operation + 1) * (observed + ChecksumOffset)

  for index in 0 ..< size:
    checksum += int64(operationCount + index + 1) * (items[index] + ChecksumOffset)
  checksum
