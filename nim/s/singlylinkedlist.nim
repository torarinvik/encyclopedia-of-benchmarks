const MaxInputValues = 227
const MaxNodes = 96
const MaxOutputBytes = 1808

type List = object
  values: array[MaxNodes, int64]
  next: array[MaxNodes, int]
  used, head, tail, length: int

proc newList(): List =
  result.head = -1
  result.tail = -1
  for node in 0 ..< MaxNodes: result.next[node] = -1

proc allocate(list: var List, value: int64): int =
  result = list.used
  inc list.used
  list.values[result] = value
  list.next[result] = -1

proc addHead(list: var List, value: int64) =
  let node = list.allocate(value)
  list.next[node] = list.head
  if list.head < 0: list.tail = node
  list.head = node
  inc list.length

proc addTail(list: var List, value: int64) =
  let node = list.allocate(value)
  if list.tail < 0: list.head = node
  else: list.next[list.tail] = node
  list.tail = node
  inc list.length

proc deleteHead(list: var List): tuple[found: bool, value: int64] =
  if list.head < 0: return (false, 0)
  let node = list.head
  result = (true, list.values[node])
  list.head = list.next[node]
  dec list.length
  if list.length == 0: list.tail = -1

proc deleteTail(list: var List): tuple[found: bool, value: int64] =
  if list.tail < 0: return (false, 0)
  result = (true, list.values[list.tail])
  if list.length == 1:
    list.head = -1
    list.tail = -1
  else:
    var previous = list.head
    while list.next[previous] != list.tail: previous = list.next[previous]
    list.next[previous] = -1
    list.tail = previous
  dec list.length

proc deletePosition(list: var List, position: int): tuple[found: bool, value: int64] =
  if list.length == 0: return (false, 0)
  if position == 1: return list.deleteHead()
  if position >= list.length: return list.deleteTail()
  var previous = list.head
  for unused in 1 ..< position - 1: previous = list.next[previous]
  let node = list.next[previous]
  result = (true, list.values[node])
  list.next[previous] = list.next[node]
  dec list.length

proc reverse(list: var List) =
  var previous = -1
  var current = list.head
  list.tail = list.head
  while current >= 0:
    let following = list.next[current]
    list.next[current] = previous
    previous = current
    current = following
  list.head = previous

proc reverseRange(list: var List, left, right: int) =
  var before = -1
  var start = list.head
  for unused in 1 ..< left:
    before = start
    start = list.next[start]
  var previous = -1
  var current = start
  for unused in left .. right:
    let following = list.next[current]
    list.next[current] = previous
    previous = current
    current = following
  list.next[start] = current
  if before < 0: list.head = previous
  else: list.next[before] = previous
  if right == list.length: list.tail = start

proc putI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (byte * 8)) and 255'u64)

proc singlylinkedlist*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "singlylinkedlist".} =
  if input == nil or length < 2 or length > MaxInputValues.csize_t: return -1
  let initialCountValue = input[0]
  let operationCountValue = input[1]
  if initialCountValue < 0 or initialCountValue > 32 or operationCountValue < 0 or operationCountValue > 64: return -1
  let initialCount = int(initialCountValue)
  let operationCount = int(operationCountValue)
  if length < csize_t(2 + initialCount): return -1
  var list = newList()
  for i in 0 ..< initialCount:
    let value = input[2 + i]
    if value < -1_000_000 or value > 1_000_000: return -1
    list.addTail(value)
  var results: array[128, int64]
  var cursor = 2 + initialCount
  for operation in 0 ..< operationCount:
    if cursor >= int(length): return -1
    let opcode = input[cursor]
    inc cursor
    var arg1 = 0'i64
    var arg2 = 0'i64
    if opcode == 0 or opcode == 1 or opcode == 4:
      if cursor >= int(length): return -1
      arg1 = input[cursor]
      inc cursor
    elif opcode == 6:
      if int(length) - cursor < 2: return -1
      arg1 = input[cursor]
      arg2 = input[cursor + 1]
      cursor += 2
    elif opcode notin [2'i64, 3'i64, 5'i64]:
      return -1
    var success = 1'i64
    var value = 0'i64
    case opcode
    of 0, 1:
      if arg1 < -1_000_000 or arg1 > 1_000_000: return -1
      if opcode == 0: list.addHead(arg1) else: list.addTail(arg1)
    of 2:
      let deleted = list.deleteHead()
      success = if deleted.found: 1 else: 0
      value = deleted.value
    of 3:
      let deleted = list.deleteTail()
      success = if deleted.found: 1 else: 0
      value = deleted.value
    of 4:
      if list.length == 0:
        if arg1 != 1: return -1
        success = 0
      else:
        if arg1 < 1 or arg1 > int64(list.length + 1): return -1
        let deleted = list.deletePosition(int(arg1))
        value = deleted.value
    of 5:
      list.reverse()
    of 6:
      if arg1 < 1 or arg2 < arg1 or arg2 > int64(list.length): return -1
      list.reverseRange(int(arg1), int(arg2))
    else: return -1
    results[operation * 2] = success
    results[operation * 2 + 1] = value
  if cursor != int(length): return -1
  let outputValues = 1 + list.length + 1 + operationCount * 2
  let outputBytes = outputValues * 8
  if outputBytes > MaxOutputBytes: return -1
  if output == nil or capacity < csize_t(outputBytes): return -2
  putI64Le(output, 0, int64(list.length))
  var offset = 8
  var node = list.head
  while node >= 0:
    putI64Le(output, offset, list.values[node])
    offset += 8
    node = list.next[node]
  putI64Le(output, offset, int64(operationCount))
  offset += 8
  for i in 0 ..< operationCount * 2:
    putI64Le(output, offset, results[i])
    offset += 8
  int64(outputBytes)
