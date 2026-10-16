const MaxArrays = 16
const MaxTotalValues = 128
const MaxParseableLength = 146
const MinValue = -1_000_000'i64
const MaxValue = 1_000_000'i64
const ChecksumOffset = 1_000_001'i64

type HeapNode = object
  value: int64
  arrayIndex: int
  elementIndex: int
type Heap = array[MaxArrays, HeapNode]

proc nodeLess(left, right: HeapNode): bool =
  if left.value != right.value: return left.value < right.value
  if left.arrayIndex != right.arrayIndex: return left.arrayIndex < right.arrayIndex
  left.elementIndex < right.elementIndex

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

proc merge_ksorted_arrays*(values: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "merge_ksorted_arrays".} =
  if values.isNil or length < 1 or length > csize_t(MaxParseableLength): return -1
  if values[0] < 1 or values[0] > int64(MaxArrays): return -1
  let arrayCount = int(values[0])
  var starts, lengths: array[MaxArrays, int]
  var position = 1
  var totalValues = 0
  for arrayIndex in 0 ..< arrayCount:
    if position >= int(length): return -1
    let declared = values[position]
    inc position
    if declared < 0 or declared > int64(MaxTotalValues - totalValues): return -1
    let arrayLength = int(declared)
    if arrayLength > int(length) - position: return -1
    starts[arrayIndex] = position
    lengths[arrayIndex] = arrayLength
    for index in 0 ..< arrayLength:
      let value = values[position + index]
      if value < MinValue or value > MaxValue or
          (index > 0 and values[position + index - 1] > value): return -1
    position += arrayLength
    totalValues += arrayLength
  if position != int(length): return -1

  var heap: Heap
  var heapSize = 0
  for arrayIndex in 0 ..< arrayCount:
    if lengths[arrayIndex] > 0:
      heapPush(heap, heapSize, HeapNode(value: values[starts[arrayIndex]],
                                      arrayIndex: arrayIndex, elementIndex: 0))
  var checksum = 0'i64
  var mergedIndex = 0'i64
  while heapSize > 0:
    let node = heapPop(heap, heapSize)
    checksum += (mergedIndex + 1) * (node.value + ChecksumOffset)
    inc mergedIndex
    let nextIndex = node.elementIndex + 1
    if nextIndex < lengths[node.arrayIndex]:
      heapPush(heap, heapSize, HeapNode(value: values[starts[node.arrayIndex] + nextIndex],
                                        arrayIndex: node.arrayIndex, elementIndex: nextIndex))
  checksum
