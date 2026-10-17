const MaxLists = 16
const MaxTotalNodes = 128
const MaxInputLength = 1 + MaxLists + MaxTotalNodes
const MaxOutputBytes = 4 * MaxTotalNodes

type
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]
  HeapNode = object
    value: int64
    listIndex: int
    nodeIndex: int
  Heap = array[MaxLists, HeapNode]

proc nodeLess(left, right: HeapNode): bool =
  if left.value != right.value: return left.value < right.value
  if left.listIndex != right.listIndex: return left.listIndex < right.listIndex
  left.nodeIndex < right.nodeIndex

proc heapPush(heap: var Heap, size: var int, node: HeapNode) =
  var index = size
  inc size
  while index > 0:
    let parent = (index - 1) div 2
    if not nodeLess(node, heap[parent]): break
    heap[index] = heap[parent]
    index = parent
  heap[index] = node

proc heapPop(heap: var Heap, size: var int): HeapNode =
  result = heap[0]
  dec size
  let last = heap[size]
  if size > 0:
    var index = 0
    while index < size div 2:
      var child = 2 * index + 1
      if child + 1 < size and nodeLess(heap[child + 1], heap[child]): inc child
      if not nodeLess(heap[child], last): break
      heap[index] = heap[child]
      index = child
    heap[index] = last

proc putI32Le(output: U8Output, offset: int, value: int64) =
  let bits = cast[uint32](int32(value))
  for byte in 0..<4:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u32)

proc merge_ksorted_linked_list*(input: I64Input, length: csize_t, output: U8Output,
    capacity: csize_t): int64
    {.cdecl, exportc: "merge_ksorted_linked_list".} =
  if input == nil or length < 1 or length > csize_t(MaxInputLength):
    return -1
  if input[0] < 0 or input[0] > int64(MaxLists):
    return -1
  let listCount = int(input[0])
  var starts, lengths: array[MaxLists, int]
  var position = 1
  var totalNodes = 0
  for listIndex in 0..<listCount:
    if position >= int(length):
      return -1
    let declared = input[position]
    inc position
    if declared < 0 or declared > int64(MaxTotalNodes - totalNodes):
      return -1
    let listLength = int(declared)
    if listLength > int(length) - position:
      return -1
    starts[listIndex] = position
    lengths[listIndex] = listLength
    for node in 0..<listLength:
      let value = input[position + node]
      if value < int64(low(int32)) or value > int64(high(int32)) or
          (node > 0 and input[position + node - 1] > value):
        return -1
    position += listLength
    totalNodes += listLength
  if position != int(length):
    return -1

  let outputBytes = 4 * totalNodes
  if output == nil or capacity < csize_t(outputBytes):
    return -2

  var heap: Heap
  var heapSize = 0
  for listIndex in 0..<listCount:
    if lengths[listIndex] > 0:
      heapPush(heap, heapSize, HeapNode(value: input[starts[listIndex]],
                                        listIndex: listIndex, nodeIndex: 0))

  var buffer: array[MaxOutputBytes, uint8]
  var written = 0
  while heapSize > 0:
    let node = heapPop(heap, heapSize)
    let out = cast[U8Output](addr buffer[0])
    putI32Le(out, written, node.value)
    written += 4
    let nextIndex = node.nodeIndex + 1
    if nextIndex < lengths[node.listIndex]:
      heapPush(heap, heapSize, HeapNode(
        value: input[starts[node.listIndex] + nextIndex],
        listIndex: node.listIndex,
        nodeIndex: nextIndex))

  for index in 0..<outputBytes:
    output[index] = buffer[index]
  int64(outputBytes)
