const MaxOperations = 64
const MaxLiveValues = 32
const MaxInputLength = 130
const MaxOutputValues = 1024

type
  Node = object
    value: int32
    left, right, nextFree: int
  SkewHeap = object
    nodes: array[MaxLiveValues, Node]
    root, freeHead, count: int

proc initialize(heap: var SkewHeap) =
  heap.root = -1; heap.count = 0; heap.freeHead = 0
  for i in 0 ..< MaxLiveValues:
    heap.nodes[i].left = -1; heap.nodes[i].right = -1
    heap.nodes[i].nextFree = if i + 1 < MaxLiveValues: i + 1 else: -1

proc merge(heap: var SkewHeap, firstArg, secondArg: int): int =
  if firstArg < 0: return secondArg
  if secondArg < 0: return firstArg
  var first = firstArg; var second = secondArg
  if heap.nodes[first].value > heap.nodes[second].value: swap(first, second)
  let oldRight = heap.nodes[first].right
  heap.nodes[first].right = heap.nodes[first].left
  heap.nodes[first].left = merge(heap, oldRight, second)
  first

proc insert(heap: var SkewHeap, value: int32): bool =
  if heap.freeHead < 0: return false
  let node = heap.freeHead; heap.freeHead = heap.nodes[node].nextFree
  heap.nodes[node] = Node(value: value, left: -1, right: -1, nextFree: -1)
  heap.root = merge(heap, heap.root, node); inc heap.count; true

proc pop(heap: var SkewHeap): int32 =
  let node = heap.root; result = heap.nodes[node].value
  heap.root = merge(heap, heap.nodes[node].left, heap.nodes[node].right)
  heap.nodes[node].nextFree = heap.freeHead; heap.freeHead = node; dec heap.count

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc skew_heap*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "skew_heap".} =
  if input.isNil or inputLength < csize_t(1) or inputLength > csize_t(MaxInputLength): return -1
  if input[0] < 0 or input[0] > MaxOperations: return -1
  let operationCount = int(input[0])
  if int(inputLength) != 1 + 2 * operationCount or inputLength > csize_t(MaxInputLength - 1): return -1
  var heap: SkewHeap; initialize(heap)
  var answers: array[MaxOutputValues, int64]; var answerCount = 0
  for operation in 0 ..< operationCount:
    let opcode = input[1 + 2 * operation]; let argument = input[2 + 2 * operation]
    if opcode < 0 or opcode > 5: return -1
    if opcode == 0:
      if argument < int64(low(int32)) or argument > int64(high(int32)) or heap.count == MaxLiveValues: return -1
      if not insert(heap, int32(argument)): return -1
    else:
      if argument != 0: return -1
      if opcode == 1:
        if heap.root < 0: return -1
        answers[answerCount] = int64(heap.nodes[heap.root].value); inc answerCount
      elif opcode == 2:
        if heap.root < 0: return -1
        answers[answerCount] = int64(pop(heap)); inc answerCount
      elif opcode == 3:
        var snapshot: array[MaxLiveValues, int32]; var snapshotCount = 0
        while heap.root >= 0: snapshot[snapshotCount] = pop(heap); inc snapshotCount
        for i in 0 ..< snapshotCount:
          if not insert(heap, snapshot[i]): return -1
          answers[answerCount] = int64(snapshot[i]); inc answerCount
      elif opcode == 4: initialize(heap)
      else:
        answers[answerCount] = if heap.count == 0: 1 else: 0; inc answerCount
  let outputBytes = csize_t(answerCount * 8)
  if output.isNil or outputCapacity < outputBytes: return -2
  for i in 0 ..< answerCount: storeI64Le(output, i * 8, answers[i])
  int64(outputBytes)
