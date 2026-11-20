const
  MaxOperations = 24
  RecordWidth = 3
  MaxInputValues = 73
  MaxIntervals = 25
  DomainEnd = 32'i64

type
  Interval = object
    left, right: int64

proc addInterval(items: var array[MaxIntervals, Interval], count: var int,
                 leftInput, rightInput: int64) =
  if leftInput == rightInput: return
  var left = leftInput
  var right = rightInput
  var next: array[MaxIntervals, Interval]
  var outCount = 0
  var inserted = false
  for index in 0 ..< count:
    let current = items[index]
    if current.right < left:
      next[outCount] = current
      inc outCount
    elif right < current.left:
      if not inserted:
        next[outCount] = Interval(left: left, right: right)
        inc outCount
        inserted = true
      next[outCount] = current
      inc outCount
    else:
      left = min(left, current.left)
      right = max(right, current.right)
  if not inserted:
    next[outCount] = Interval(left: left, right: right)
    inc outCount
  for index in 0 ..< outCount: items[index] = next[index]
  count = outCount

proc removeInterval(items: var array[MaxIntervals, Interval], count: var int,
                    left, right: int64) =
  if left == right: return
  var next: array[MaxIntervals + 1, Interval]
  var outCount = 0
  for index in 0 ..< count:
    let current = items[index]
    if current.right <= left or current.left >= right:
      next[outCount] = current
      inc outCount
    else:
      if current.left < left:
        next[outCount] = Interval(left: current.left, right: left)
        inc outCount
      if current.right > right:
        next[outCount] = Interval(left: right, right: current.right)
        inc outCount
  for index in 0 ..< outCount: items[index] = next[index]
  count = outCount

proc coveredLength(items: array[MaxIntervals, Interval], count: int): int64 =
  var total = 0'i64
  for index in 0 ..< count: total += items[index].right - items[index].left
  total

proc validInput(input: ptr UncheckedArray[int64], length: csize_t): int =
  if input == nil or length < 1 or length > csize_t(MaxInputValues): return -1
  if input[0] < 0 or input[0] > MaxOperations: return -1
  let operationCount = int(input[0])
  if length != csize_t(1 + operationCount * RecordWidth): return -1
  for index in 0 ..< operationCount:
    let offset = 1 + index * RecordWidth
    let opcode = input[offset]
    let left = input[offset + 1]
    let right = input[offset + 2]
    if opcode < 0 or opcode > 1 or left < 0 or right < left or right > DomainEnd:
      return -1
  operationCount

proc interval_container*(input: ptr UncheckedArray[int64],
                         length: csize_t): int64 {.cdecl, exportc: "interval_container".} =
  let operationCount = validInput(input, length)
  if operationCount < 0: return -1
  var items: array[MaxIntervals, Interval]
  var count = 0
  var checksum = 0'i64
  for index in 0 ..< operationCount:
    let offset = 1 + index * RecordWidth
    let opcode = input[offset]
    let left = input[offset + 1]
    let right = input[offset + 2]
    if opcode == 0: addInterval(items, count, left, right)
    else: removeInterval(items, count, left, right)
    checksum += int64(index + 1) * coveredLength(items, count)
  checksum
