const MaxListLength = 32
const MaxTotalNodes = 2 * MaxListLength
const MaxParseableInputLength = 2 + MaxTotalNodes + 1

type Node = object
  value: int32
  next: int32

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc merge_linked_lists*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc.} =
  if values == nil or length < 2 or length > csize_t(MaxParseableInputLength): return -1
  let rawFirst = values[0]
  let rawSecond = values[1]
  if rawFirst < 0 or rawFirst > MaxListLength or rawSecond < 0 or rawSecond > MaxListLength: return -1
  let firstLength = int(rawFirst)
  let secondLength = int(rawSecond)
  let total = firstLength + secondLength
  if total > MaxTotalNodes or int(length) != 2 + total: return -1

  var nodes: array[MaxTotalNodes, Node]
  for index in 0 ..< firstLength:
    let value = values[2 + index]
    if value < int64(low(int32)) or value > int64(high(int32)): return -1
    nodes[index].value = int32(value)
    nodes[index].next = if index + 1 < firstLength: int32(index + 1) else: -1
  let secondStart = firstLength
  for index in 0 ..< secondLength:
    let value = values[2 + firstLength + index]
    if value < int64(low(int32)) or value > int64(high(int32)): return -1
    let node = secondStart + index
    nodes[node].value = int32(value)
    nodes[node].next = if index + 1 < secondLength: int32(node + 1) else: -1

  let head1 = if firstLength == 0: -1'i32 else: 0'i32
  let head2 = if secondLength == 0: -1'i32 else: int32(secondStart)
  var temp1 = head1
  var temp2 = head2
  var holder2 = -1'i32
  while temp1 != -1 and temp2 != -1:
    let holder1 = nodes[int(temp1)].next
    nodes[int(temp1)].next = temp2
    if holder1 != -1:
      holder2 = nodes[int(temp2)].next
      nodes[int(temp2)].next = holder1
    temp1 = holder1
    temp2 = holder2

  var outputCount = 0
  var node = head1
  while node != -1:
    if node < 0 or int(node) >= total or outputCount >= total: return -1
    inc outputCount
    node = nodes[int(node)].next
  let required = outputCount * 8
  if output == nil or capacity < csize_t(required): return -2

  node = head1
  for index in 0 ..< outputCount:
    storeI64Le(output, 8 * index, int64(nodes[int(node)].value))
    node = nodes[int(node)].next
  int64(required)
