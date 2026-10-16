type I64Input = ptr UncheckedArray[int64]
type U8Output = ptr UncheckedArray[uint8]

const MaxNodes = 64
const MaxOperations = 64
const MaxRecordFields = 5000

proc rotateList(next, previous: var array[MaxNodes, int64], head: var int64, size, places: int64) =
  if size == 0: return
  var steps = places mod size
  if steps < 0: steps += size
  if steps > size div 2:
    steps = size - steps
    for _ in 0 ..< int(steps): head = previous[int(head)]
  else:
    for _ in 0 ..< int(steps): head = next[int(head)]

proc deleteHead(values: var array[MaxNodes, int64], next: var array[MaxNodes, int64],
    previous: var array[MaxNodes, int64], head: var int64, size: var int64): bool =
  if size == 0: return false
  let current = int(head)
  if size == 1: head = -1
  else:
    let successor = next[current]
    let predecessor = previous[current]
    next[int(predecessor)] = successor
    previous[int(successor)] = predecessor
    head = successor
  values[current] = 0
  dec size
  true

proc addRecord(records: var array[MaxRecordFields, int64], fieldCount: var int, value: int64) =
  records[fieldCount] = value
  inc fieldCount

proc putI64(output: U8Output, offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byteIndex in 0 ..< 8: output[offset + byteIndex] = uint8((bits shr (byteIndex * 8)) and 255)

proc cyclic*(input: I64Input, length: csize_t, output: U8Output, capacity: csize_t): int64 {.cdecl, exportc: "cyclic".} =
  if input == nil or length < 1 or input[0] < 0 or input[0] > MaxOperations: return -1
  let operationCount = int(input[0])
  if int(length) != 1 + 2 * operationCount: return -1
  var values: array[MaxNodes, int64]
  var next: array[MaxNodes, int64]
  var previous: array[MaxNodes, int64]
  var head = -1'i64
  var size = 0'i64
  var allocated = 0
  var records: array[MaxRecordFields, int64]
  var recordFields = 0
  var queryCount = 0

  for index in 0 ..< operationCount:
    let operation = input[1 + 2 * index]
    let argument = input[2 + 2 * index]
    if operation < 0 or operation > 5: return -1
    if operation == 0:
      if argument < int64(low(int32)) or argument > int64(high(int32)) or allocated >= MaxNodes: return -1
      let node = allocated
      inc allocated
      values[node] = argument
      if size == 0:
        head = int64(node)
        next[node] = head
        previous[node] = head
      else:
        let tail = int(previous[int(head)])
        previous[node] = int64(tail)
        next[node] = head
        next[tail] = int64(node)
        previous[int(head)] = int64(node)
      inc size
    elif operation == 1:
      if argument < -1_000_000 or argument > 1_000_000: return -1
      rotateList(next, previous, head, size, argument)
    elif operation == 2:
      if argument != 0: return -1
      let deleted = if deleteHead(values, next, previous, head, size): 1'i64 else: 0'i64
      addRecord(records, recordFields, int64(index)); addRecord(records, recordFields, operation)
      addRecord(records, recordFields, 1); addRecord(records, recordFields, deleted); inc queryCount
    elif operation == 3:
      if argument != 0: return -1
      addRecord(records, recordFields, int64(index)); addRecord(records, recordFields, operation); addRecord(records, recordFields, size)
      var cursor = head
      for _ in 0 ..< int(size): addRecord(records, recordFields, values[int(cursor)]); cursor = next[int(cursor)]
      inc queryCount
    elif operation == 4:
      if argument < -1_000_000 or argument > 1_000_000 or size == 0: return -1
      while size > 1:
        rotateList(next, previous, head, size, argument)
        discard deleteHead(values, next, previous, head, size)
        rotateList(next, previous, head, size, -1)
      let winner = values[int(head)]
      while deleteHead(values, next, previous, head, size): discard
      addRecord(records, recordFields, int64(index)); addRecord(records, recordFields, operation)
      addRecord(records, recordFields, 1); addRecord(records, recordFields, winner); inc queryCount
    else:
      if argument != 0: return -1
      while deleteHead(values, next, previous, head, size): discard

  let required = (1 + recordFields + 1 + int(size)) * 8
  if output == nil or capacity < csize_t(required): return -2
  var field = 0
  putI64(output, field * 8, int64(queryCount)); inc field
  for i in 0 ..< recordFields: putI64(output, field * 8, records[i]); inc field
  putI64(output, field * 8, size); inc field
  var cursor = head
  for _ in 0 ..< int(size): putI64(output, field * 8, values[int(cursor)]); inc field; cursor = next[int(cursor)]
  int64(required)
