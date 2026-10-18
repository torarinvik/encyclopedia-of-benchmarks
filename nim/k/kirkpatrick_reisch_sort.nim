const
  MaxElements = 256
  MaxBlocks = 17
  MaxParseableInputLength = 258
  MaxOutputBytes = 2048

type HeapNode = object
  value: int64
  blockIndex: int
  offset: int

proc less(left, right: HeapNode): bool =
  if left.value != right.value: return left.value < right.value
  if left.blockIndex != right.blockIndex: return left.blockIndex < right.blockIndex
  left.offset < right.offset

proc heapPush(heap: var array[MaxBlocks, HeapNode], length: var int, value: HeapNode) =
  var position = length
  inc length
  while position > 0:
    let parent = (position - 1) div 2
    if not less(value, heap[parent]): break
    heap[position] = heap[parent]
    position = parent
  heap[position] = value

proc heapPop(heap: var array[MaxBlocks, HeapNode], length: var int): HeapNode =
  result = heap[0]
  dec length
  let last = heap[length]
  if length == 0: return
  var position = 0
  while position * 2 + 1 < length:
    var child = position * 2 + 1
    if child + 1 < length and less(heap[child + 1], heap[child]): inc child
    if not less(heap[child], last): break
    heap[position] = heap[child]
    position = child
  heap[position] = last

proc writeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 0xff'u64)

proc kirkpatrickReischSort*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "kirkpatrick_reisch_sort".} =
  if input == nil or inputLength < 1 or inputLength > MaxParseableInputLength.csize_t: return -1
  if input[0] < 0 or input[0] > MaxElements.int64: return -1
  let count = int(input[0])
  if inputLength != csize_t(count + 1): return -1

  var blocks: array[MaxElements, int64]
  for index in 0 ..< count: blocks[index] = input[index + 1]
  var starts, lengths: array[MaxBlocks, int]
  var blockCount = 0
  var blockSize = 1
  if count > 1:
    while (blockSize + 1) * (blockSize + 1) <= count: inc blockSize
    var start = 0
    while start < count:
      let length = min(count - start, blockSize)
      starts[blockCount] = start
      lengths[blockCount] = length
      inc blockCount
      for index in 1 ..< length:
        let value = blocks[start + index]
        var position = index
        while position > 0 and blocks[start + position - 1] > value:
          blocks[start + position] = blocks[start + position - 1]
          dec position
        blocks[start + position] = value
      start += blockSize
  elif count == 1:
    starts[0] = 0
    lengths[0] = 1
    blockCount = 1

  var sorted: array[MaxElements, int64]
  var sortedCount = 0
  var heap: array[MaxBlocks, HeapNode]
  var heapLength = 0
  for block in 0 ..< blockCount:
    heapPush(heap, heapLength, HeapNode(value: blocks[starts[block]], blockIndex: block, offset: 0))
  while heapLength > 0:
    let current = heapPop(heap, heapLength)
    sorted[sortedCount] = current.value
    inc sortedCount
    let next = current.offset + 1
    if next < lengths[current.blockIndex]:
      heapPush(heap, heapLength, HeapNode(value: blocks[starts[current.blockIndex] + next], blockIndex: current.blockIndex, offset: next))

  let outputBytes = sortedCount * 8
  if outputBytes > MaxOutputBytes: return -1
  if output == nil or capacity < csize_t(outputBytes): return -2
  for index in 0 ..< sortedCount: writeI64Le(output, index * 8, sorted[index])
  int64(outputBytes)
