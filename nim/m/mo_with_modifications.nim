const MaxN = 64
const MaxQ = 64
const MaxInputLength = 258

type Query = object
  left: int
  right: int
  time: int
  ordinal: int

type Change = object
  position: int
  beforeValue: int
  afterValue: int

type Window = object
  values: array[MaxN, int]
  frequencies: array[16, int]
  distinctCount: int
  left: int
  right: int

proc addValue(window: var Window, position: int) =
  let value = window.values[position]
  if window.frequencies[value] == 0: inc window.distinctCount
  inc window.frequencies[value]

proc removeValue(window: var Window, position: int) =
  let value = window.values[position]
  dec window.frequencies[value]
  if window.frequencies[value] == 0: dec window.distinctCount

proc replaceValue(window: var Window, position, newValue: int) =
  if position >= window.left and position <= window.right: removeValue(window, position)
  window.values[position] = newValue
  if position >= window.left and position <= window.right: addValue(window, position)

proc queryBefore(a, b: Query, blockSize: int): bool =
  let leftBlockA = a.left div blockSize
  let leftBlockB = b.left div blockSize
  if leftBlockA != leftBlockB: return leftBlockA < leftBlockB
  let rightBlockA = a.right div blockSize
  let rightBlockB = b.right div blockSize
  if rightBlockA != rightBlockB: return rightBlockA < rightBlockB
  if a.time != b.time: return a.time < b.time
  a.ordinal < b.ordinal

proc mo_with_modifications*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "mo_with_modifications".} =
  if input == nil or length < 2 or length > csize_t(MaxInputLength): return -1
  let n64 = input[0]
  let q64 = input[1]
  if n64 < 1 or n64 > int64(MaxN) or q64 < 0 or q64 > int64(MaxQ) or
      length != csize_t(2'i64 + n64 + 3'i64 * q64): return -1
  let n = int(n64)
  let q = int(q64)

  var initial: array[MaxN, int]
  for i in 0 ..< n:
    let value = input[2 + i]
    if value < 0 or value > 15: return -1
    initial[i] = int(value)

  let operationOffset = 2 + n
  for i in 0 ..< q:
    let operation = input[operationOffset + 3 * i]
    let first = input[operationOffset + 3 * i + 1]
    let second = input[operationOffset + 3 * i + 2]
    if operation == 0:
      if first < 0 or first >= n64 or second < 0 or second > 15: return -1
    elif operation == 1:
      if first < 0 or second < first or second >= n64: return -1
    else:
      return -1

  var parseState = initial
  var changes: array[MaxQ, Change]
  var queries: array[MaxQ, Query]
  var changeCount = 0
  var queryCount = 0
  for i in 0 ..< q:
    let operation = input[operationOffset + 3 * i]
    let first = int(input[operationOffset + 3 * i + 1])
    let second = int(input[operationOffset + 3 * i + 2])
    if operation == 0:
      changes[changeCount] = Change(position: first, beforeValue: parseState[first], afterValue: second)
      parseState[first] = second
      inc changeCount
    else:
      queries[queryCount] = Query(left: first, right: second, time: changeCount, ordinal: queryCount)
      inc queryCount

  var blockSize = 1
  while (blockSize + 1) * (blockSize + 1) * (blockSize + 1) <= n * n: inc blockSize
  for i in 1 ..< queryCount:
    let current = queries[i]
    var position = i
    while position > 0 and queryBefore(current, queries[position - 1], blockSize):
      queries[position] = queries[position - 1]
      dec position
    queries[position] = current

  var window: Window
  window.values = initial
  window.left = 0
  window.right = -1
  var currentTime = 0
  var answers: array[MaxQ, int]
  for queryIndex in 0 ..< queryCount:
    let query = queries[queryIndex]
    while currentTime < query.time:
      let change = changes[currentTime]
      replaceValue(window, change.position, change.afterValue)
      inc currentTime
    while currentTime > query.time:
      dec currentTime
      let change = changes[currentTime]
      replaceValue(window, change.position, change.beforeValue)
    while window.left > query.left:
      dec window.left
      addValue(window, window.left)
    while window.right < query.right:
      inc window.right
      addValue(window, window.right)
    while window.left < query.left:
      removeValue(window, window.left)
      inc window.left
    while window.right > query.right:
      removeValue(window, window.right)
      dec window.right
    answers[query.ordinal] = window.distinctCount

  var checksum = 0'i64
  for ordinal in 0 ..< queryCount:
    checksum += int64(ordinal + 1) * int64(answers[ordinal] + 1)
  checksum
