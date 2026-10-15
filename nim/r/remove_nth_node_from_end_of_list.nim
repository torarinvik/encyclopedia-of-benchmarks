## Remove a node by one-based distance from the tail in an index-based list.
const MaxListLength = 1024

proc remove_nth_node_from_end_of_list*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "remove_nth_node_from_end_of_list".} =
  if input == nil or length < 2 or length > csize_t(MaxListLength + 1): return -1
  let listLength = int(length) - 1
  for index in 0 ..< listLength:
    if input[index + 1] < int64(low(int32)) or input[index + 1] > int64(high(int32)): return -1
  if input[0] < 1 or input[0] > int64(listLength): return -1

  var nextNode: array[MaxListLength, int]
  for index in 0 ..< listLength:
    if index + 1 < listLength: nextNode[index] = index + 1
    else: nextNode[index] = MaxListLength
  var node = 0
  var counted = 0
  while node != MaxListLength:
    node = nextNode[node]
    inc counted
  if counted != listLength: return -1

  let stepsToTarget = counted - int(input[0])
  var before = MaxListLength
  node = 0
  for _ in 0 ..< stepsToTarget:
    before = node
    node = nextNode[node]
  let head = if before == MaxListLength: nextNode[node] else: 0
  if before != MaxListLength: nextNode[before] = nextNode[node]

  let outputCount = counted - 1
  let outputBytes = outputCount * 4
  if outputCapacity < csize_t(outputBytes) or (outputBytes != 0 and output == nil): return -2
  node = head
  var written = 0
  while node != MaxListLength:
    let bits = cast[uint32](int32(input[node + 1]))
    for byte in 0 ..< 4:
      output[written * 4 + byte] = uint8((bits shr (byte * 8)) and 0xff'u32)
    node = nextNode[node]
    inc written
  if written != outputCount: return -1
  int64(written)
