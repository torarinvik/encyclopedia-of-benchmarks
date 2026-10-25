const MaxLists = 4
const MaxInitialLength = 4
const MaxIterations = 16
const MaxNodes = 36

proc storeLeI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc llubenchmark_list_traversal_growth*(input: ptr UncheckedArray[int64],
    inputLength: csize_t, output: ptr UncheckedArray[uint8],
    outputCapacity: csize_t): int64 {.cdecl, exportc: "llubenchmark_list_traversal_growth".} =
  if input == nil or inputLength != 3: return -1
  let listValue = input[0]
  let initialValue = input[1]
  let iterationValue = input[2]
  if listValue < 1 or listValue > MaxLists or initialValue < 1 or
      initialValue > MaxInitialLength or iterationValue < 0 or
      iterationValue > MaxIterations: return -1
  if output == nil or outputCapacity < 16: return -2
  let listCount = int(listValue)
  let initialLength = int(initialValue)
  let iterations = int(iterationValue)

  var nextNode: array[MaxNodes, int64]
  var nodeCount: array[MaxNodes, int64]
  var head: array[MaxLists, int64]
  var tail: array[MaxLists, int64]
  for i in 0..<MaxNodes: nextNode[i] = -1
  for i in 0..<MaxLists: head[i] = -1; tail[i] = -1
  var allocated = 0
  for _ in 0..<initialLength:
    for list in 0..<listCount:
      let node = allocated
      inc allocated
      nextNode[node] = head[list]
      head[list] = int64(node)
      if tail[list] == -1: tail[list] = int64(node)

  var accumulate = 0'i64
  var growthMilli = 0
  for _ in 0..<iterations:
    for list in 0..<listCount:
      var node = head[list]
      while node != -1:
        let index = int(node)
        accumulate += nodeCount[index]
        inc nodeCount[index]
        node = nextNode[index]
    growthMilli += 333
    let insertions = growthMilli div 1000
    growthMilli -= insertions * 1000
    if insertions > 0:
      for ordinal in countdown(insertions, 1):
        for list in 0..<listCount:
          let node = allocated
          inc allocated
          nodeCount[node] = int64(list + ordinal)
          nextNode[node] = -1
          nextNode[int(tail[list])] = int64(node)
          tail[list] = int64(node)
  storeLeI64(output, 0, accumulate)
  storeLeI64(output, 8, int64(allocated))
  return 2
