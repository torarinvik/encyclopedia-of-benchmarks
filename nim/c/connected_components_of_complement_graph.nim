const MaxN = 64
const MaxM = MaxN * (MaxN - 1) div 2
const MaxInputValues = 2 + 2 * MaxM
const MaxOutputValues = 1 + 2 * MaxN

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc connected_components_of_complement_graph*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "connected_components_of_complement_graph".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputValues): return -1
  let nValue = input[0]
  let mValue = input[1]
  if nValue < 1 or nValue > MaxN or mValue < 0: return -1
  if mValue > nValue * (nValue - 1) div 2: return -1
  let n = int(nValue)
  let m = int(mValue)
  if length != csize_t(2 + 2 * m): return -1

  var graph: array[MaxN, uint64]
  for edge in 0 ..< m:
    let leftValue = input[2 + 2 * edge]
    let rightValue = input[3 + 2 * edge]
    if leftValue < 0 or leftValue >= nValue or rightValue < 0 or
       rightValue >= nValue or leftValue == rightValue: return -1
    let left = int(leftValue)
    let right = int(rightValue)
    let bit = 1'u64 shl right
    if (graph[left] and bit) != 0: return -1
    graph[left] = graph[left] or bit
    graph[right] = graph[right] or (1'u64 shl left)

  var remaining, queue: array[MaxN, int]
  var label: array[MaxN, int]
  for vertex in 0 ..< n:
    remaining[vertex] = vertex
    label[vertex] = -1
  var remainingCount = n
  var componentCount = 0
  while remainingCount > 0:
    dec remainingCount
    let root = remaining[remainingCount]
    label[root] = componentCount
    var head = 0
    var tail = 1
    queue[0] = root
    while head < tail:
      let vertex = queue[head]
      inc head
      var position = 0
      while position < remainingCount:
        let candidate = remaining[position]
        if ((graph[vertex] shr candidate) and 1) != 0:
          inc position
        else:
          dec remainingCount
          remaining[position] = remaining[remainingCount]
          label[candidate] = componentCount
          queue[tail] = candidate
          inc tail
    inc componentCount

  var staged: array[MaxOutputValues, int64]
  var used = 0
  staged[used] = int64(componentCount)
  inc used
  var emitted: array[MaxN, bool]
  for first in 0 ..< n:
    let component = label[first]
    if emitted[component]: continue
    emitted[component] = true
    var componentSize = 0
    for vertex in 0 ..< n:
      if label[vertex] == component: inc componentSize
    staged[used] = int64(componentSize)
    inc used
    for vertex in 0 ..< n:
      if label[vertex] == component:
        staged[used] = int64(vertex)
        inc used

  let required = 8 * used
  if output.isNil or capacity < csize_t(required): return -2
  for index in 0 ..< used: storeI64Le(output, 8 * index, staged[index])
  int64(required)
