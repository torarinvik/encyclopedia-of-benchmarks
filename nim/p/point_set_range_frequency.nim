const
  MaxN = 64
  MaxQ = 64
  MaxValues = MaxN + MaxQ
  Stride = MaxN + 1
  MaxTree = MaxValues * Stride
  MaxParseableInput = 2 + MaxN + 4 * MaxQ + 1
  MaxOutputBytes = 8 * MaxQ
  MaxValue = 1_000_000'i64

type
  Operation = object
    kind, a, b, c: int64

proc lowbit(value: int): int = value and -value

proc lowerBound(values: openArray[int64], count: int, target: int64): int =
  var left = 0
  var right = count
  while left < right:
    let middle = left + (right - left) div 2
    if values[middle] < target: left = middle + 1
    else: right = middle
  left

proc sortUnique(values: var array[MaxValues, int64], count: int): int =
  for index in 1 ..< count:
    let value = values[index]
    var position = index
    while position > 0 and values[position - 1] > value:
      values[position] = values[position - 1]
      dec position
    values[position] = value
  var uniqueCount = 0
  for index in 0 ..< count:
    if uniqueCount == 0 or values[index] != values[uniqueCount - 1]:
      values[uniqueCount] = values[index]
      inc uniqueCount
  uniqueCount

proc fenwickAdd(tree: var array[MaxTree, int64], valueId, position, n: int, delta: int64) =
  var index = position + 1
  let row = valueId * Stride
  while index <= n:
    tree[row + index] += delta
    index += lowbit(index)

proc fenwickPrefix(tree: openArray[int64], valueId, count: int): int64 =
  var index = count
  let row = valueId * Stride
  while index > 0:
    result += tree[row + index]
    index -= lowbit(index)

proc putI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc point_set_range_frequency*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "point_set_range_frequency".} =
  if input.isNil or length < 2 or length > csize_t(MaxParseableInput): return -1
  let nValue = input[0]
  let qValue = input[1]
  if nValue < 1 or nValue > MaxN or qValue < 0 or qValue > MaxQ: return -1
  let n = int(nValue)
  let q = int(qValue)
  if 2 + n > int(length): return -1
  var values: array[MaxValues, int64]
  var initial: array[MaxN, int64]
  var operations: array[MaxQ, Operation]
  var valueCount = 0
  for index in 0 ..< n:
    let value = input[2 + index]
    if value < 0 or value > MaxValue: return -1
    initial[index] = value
    values[valueCount] = value
    inc valueCount
  var cursor = 2 + n
  var queryCount = 0
  for index in 0 ..< q:
    if cursor >= int(length): return -1
    let kind = input[cursor]
    inc cursor
    if kind == 0:
      if cursor + 2 > int(length): return -1
      let position = input[cursor]
      let value = input[cursor + 1]
      cursor += 2
      if position < 0 or position >= nValue or value < 0 or value > MaxValue: return -1
      operations[index] = Operation(kind: kind, a: position, b: value)
      values[valueCount] = value
      inc valueCount
    elif kind == 1:
      if cursor + 3 > int(length): return -1
      let left = input[cursor]
      let right = input[cursor + 1]
      let value = input[cursor + 2]
      cursor += 3
      if left < 0 or left > right or right > nValue or value < 0 or value > MaxValue: return -1
      operations[index] = Operation(kind: kind, a: left, b: right, c: value)
      inc queryCount
    else: return -1
  if cursor != int(length): return -1
  let outputBytes = 8 * queryCount
  if outputBytes > 0 and (output.isNil or capacity < csize_t(outputBytes)): return -2

  let uniqueCount = sortUnique(values, valueCount)
  var tree: array[MaxTree, int64]
  var current: array[MaxN, int]
  for index in 0 ..< n:
    current[index] = lowerBound(values, uniqueCount, initial[index])
    fenwickAdd(tree, current[index], index, n, 1)
  var answer = 0
  for index in 0 ..< q:
    let operation = operations[index]
    if operation.kind == 0:
      let position = int(operation.a)
      let next = lowerBound(values, uniqueCount, operation.b)
      if current[position] != next:
        fenwickAdd(tree, current[position], position, n, -1)
        fenwickAdd(tree, next, position, n, 1)
        current[position] = next
    else:
      let id = lowerBound(values, uniqueCount, operation.c)
      var count = 0'i64
      if id < uniqueCount and values[id] == operation.c:
        count = fenwickPrefix(tree, id, int(operation.b)) - fenwickPrefix(tree, id, int(operation.a))
      putI64Le(output, 8 * answer, count)
      inc answer
  int64(outputBytes)
