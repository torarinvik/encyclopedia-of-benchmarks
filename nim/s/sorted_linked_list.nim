const MaxInitialCount = 16
const MaxInputLength = 20
const MaxOutputWords = 18

type ListNode = object
  value: int64
  next: int

proc putI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xff'u64)

proc sorted_linked_list*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "sorted_linked_list".} =
  if input == nil or inputLength < 3 or inputLength > MaxInputLength.csize_t: return -1
  if input[0] < 0 or input[0] > MaxInitialCount: return -1
  let count = int(input[0])
  if inputLength != csize_t(count + 3): return -1

  var nodes: array[MaxInitialCount + 1, ListNode]
  for index in 0 ..< count:
    let value = input[index + 1]
    if value < int64(low(int32)) or value > int64(high(int32)): return -1
    if index > 0 and input[index] >= value: return -1
    nodes[index].value = value
    nodes[index].next = if index + 1 < count: index + 1 else: -1
  let operationValue = input[count + 1]
  let key = input[count + 2]
  if operationValue < 0 or operationValue > 2 or
      key < int64(low(int32)) or key > int64(high(int32)): return -1
  let operation = int(operationValue)
  var head = if count == 0: -1 else: 0
  var tail = if count == 0: -1 else: count - 1

  if operation == 0:
    var current = head
    while current >= 0:
      if nodes[current].value == key: return -1
      current = nodes[current].next

  var staged: array[MaxOutputWords, int64]
  var wordCount = 0
  if operation == 0:
    let newNode = count
    nodes[newNode].value = key
    nodes[newNode].next = -1
    if head < 0:
      head = newNode
      tail = newNode
    elif key < nodes[head].value:
      nodes[newNode].next = head
      head = newNode
    elif key > nodes[tail].value:
      nodes[tail].next = newNode
      tail = newNode
    else:
      var previous = head
      while nodes[previous].next >= 0 and nodes[nodes[previous].next].value < key:
        previous = nodes[previous].next
      nodes[newNode].next = nodes[previous].next
      nodes[previous].next = newNode
      if nodes[newNode].next < 0: tail = newNode
    staged[wordCount] = int64(count + 1)
    inc wordCount
    var current = head
    while current >= 0:
      staged[wordCount] = nodes[current].value
      inc wordCount
      current = nodes[current].next
  elif operation == 1:
    var found = 0'i64
    var current = head
    while current >= 0:
      if nodes[current].value == key:
        found = 1
        break
      current = nodes[current].next
    staged[wordCount] = found
    inc wordCount
  else:
    var deleted = 0'i64
    if head >= 0 and nodes[head].value == key:
      head = nodes[head].next
      if head < 0: tail = -1
      deleted = 1
    else:
      var previous = head
      while previous >= 0 and nodes[previous].next >= 0:
        let candidate = nodes[previous].next
        if nodes[candidate].value == key:
          nodes[previous].next = nodes[candidate].next
          if tail == candidate: tail = previous
          deleted = 1
          break
        previous = candidate
    staged[wordCount] = deleted
    inc wordCount
    var remaining = 0
    var current = head
    while current >= 0:
      inc remaining
      current = nodes[current].next
    staged[wordCount] = int64(remaining)
    inc wordCount
    current = head
    while current >= 0:
      staged[wordCount] = nodes[current].value
      inc wordCount
      current = nodes[current].next

  let outputBytes = wordCount * 8
  if output == nil or capacity < csize_t(outputBytes): return -2
  for index in 0 ..< wordCount: putI64Le(output, index * 8, staged[index])
  int64(outputBytes)
