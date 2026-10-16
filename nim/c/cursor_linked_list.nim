type I64Input = ptr UncheckedArray[int64]
type U8Output = ptr UncheckedArray[uint8]

const CursorSpaceSize = 100
const MaxOperations = 64

proc findValue(elements: var array[CursorSpaceSize, int64], occupied: var array[CursorSpaceSize, bool],
    links: var array[CursorSpaceSize, int64], head, value: int64): tuple[previous, found: int64] =
  result.previous = -1
  result.found = head
  while result.found != -1 and (not occupied[int(result.found)] or elements[int(result.found)] != value):
    result.previous = result.found
    result.found = links[int(result.found)]

proc freeNode(elements: var array[CursorSpaceSize, int64], occupied: var array[CursorSpaceSize, bool],
    links: var array[CursorSpaceSize, int64], index: int) =
  let oldFreeHead = links[0]
  occupied[index] = false
  elements[index] = 0
  links[index] = oldFreeHead
  links[0] = int64(index)

proc removeValue(elements: var array[CursorSpaceSize, int64], occupied: var array[CursorSpaceSize, bool],
    links: var array[CursorSpaceSize, int64], head: var int64, count: var int64, value: int64): bool =
  if head == -1: return false
  let found = findValue(elements, occupied, links, head, value)
  if found.found == -1: return false
  let successor = links[int(found.found)]
  if found.previous == -1:
    freeNode(elements, occupied, links, int(found.found))
    head = successor
  else:
    links[int(found.previous)] = successor
    freeNode(elements, occupied, links, int(found.found))
  dec count
  true

proc putI64(output: U8Output, offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byteIndex in 0 ..< 8:
    output[offset + byteIndex] = uint8((bits shr (byteIndex * 8)) and 255)

proc cursor_linked_list*(values: I64Input, length: csize_t, output: U8Output,
    outputCapacity: csize_t): int64 {.cdecl, exportc: "cursor_linked_list".} =
  if values == nil or length < 1 or values[0] < 0 or values[0] > MaxOperations: return -1
  let operationCount = int(values[0])
  if int(length) != 1 + 2 * operationCount: return -1
  var elements: array[CursorSpaceSize, int64]
  var links: array[CursorSpaceSize, int64]
  var occupied: array[CursorSpaceSize, bool]
  for i in 0 ..< CursorSpaceSize: links[i] = int64(i + 1)
  links[CursorSpaceSize - 1] = 0
  var head = -1'i64
  var count = 0'i64
  var queryFound: array[MaxOperations, int64]
  var queryValues: array[MaxOperations, int64]
  var queryCount = 0

  for index in 0 ..< operationCount:
    let operation = values[1 + 2 * index]
    let argument = values[2 + 2 * index]
    if operation < 0 or operation > 4 or argument < int64(low(int32)) or argument > int64(high(int32)): return -1
    if operation == 0:
      let available = int(links[0])
      if available == 0: return -1
      links[0] = links[available]
      links[available] = -1
      elements[available] = argument
      occupied[available] = true
      if head == -1: head = int64(available)
      else:
        var tail = int(head)
        while links[tail] != -1: tail = int(links[tail])
        links[tail] = int64(available)
      links[available] = -1
      inc count
    elif operation == 1:
      if not removeValue(elements, occupied, links, head, count, argument): return -1
    elif operation == 2:
      if argument < 0 or argument >= count: return -1
      var cursor = int(head)
      for _ in 0 ..< int(argument): cursor = int(links[cursor])
      let value = elements[cursor]
      if not removeValue(elements, occupied, links, head, count, value): return -1
    elif operation == 3:
      if argument >= 0 and argument < count:
        var cursor = int(head)
        for _ in 0 ..< int(argument): cursor = int(links[cursor])
        queryFound[queryCount] = 1
        queryValues[queryCount] = elements[cursor]
      inc queryCount
    else:
      let found = findValue(elements, occupied, links, head, argument)
      if found.found != -1:
        var cursor = head
        var logicalIndex = 0'i64
        while cursor != found.found:
          cursor = links[int(cursor)]
          inc logicalIndex
        queryFound[queryCount] = 1
        queryValues[queryCount] = logicalIndex
      inc queryCount

  let required = (1 + 2 * queryCount + 2 + 3 * CursorSpaceSize) * 8
  if output == nil or outputCapacity < csize_t(required): return -2
  var field = 0
  putI64(output, field * 8, int64(queryCount)); inc field
  for i in 0 ..< queryCount:
    putI64(output, field * 8, queryFound[i]); inc field
    putI64(output, field * 8, queryValues[i]); inc field
  putI64(output, field * 8, head); inc field
  putI64(output, field * 8, count); inc field
  for i in 0 ..< CursorSpaceSize:
    putI64(output, field * 8, if occupied[i]: 1 else: 0); inc field
    putI64(output, field * 8, elements[i]); inc field
    putI64(output, field * 8, links[i]); inc field
  int64(required)
