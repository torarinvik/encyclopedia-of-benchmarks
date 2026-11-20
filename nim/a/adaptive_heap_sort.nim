import std/ffi

const MaxValues = 1024
type IndexArray = array[MaxValues, csize_t]

proc nodeLess(values: ptr UncheckedArray[int64], left, right: csize_t): bool =
  values[left] < values[right] or (values[left] == values[right] and left < right)

proc pushCandidate(values: ptr UncheckedArray[int64], heap: var IndexArray,
                   heapLength: var csize_t, node: csize_t) =
  var position = heapLength
  inc heapLength
  heap[position] = node
  while position > 0:
    let parent = (position - 1) div 2
    if not nodeLess(values, heap[position], heap[parent]): break
    swap(heap[position], heap[parent])
    position = parent

proc popCandidate(values: ptr UncheckedArray[int64], heap: var IndexArray,
                  heapLength: var csize_t): csize_t =
  result = heap[0]
  dec heapLength
  if heapLength == 0: return
  heap[0] = heap[heapLength]
  var position = csize_t(0)
  while position < heapLength div 2:
    var child = position * 2 + 1
    if child + 1 < heapLength and nodeLess(values, heap[child + 1], heap[child]):
      inc child
    if not nodeLess(values, heap[child], heap[position]): break
    swap(heap[position], heap[child])
    position = child

proc adaptive_heap_sort*(values: ptr UncheckedArray[int64], length: csize_t)
    {.cdecl, exportc: "adaptive_heap_sort".} =
  if values == nil or length < 2 or length > csize_t(MaxValues): return
  let n = int(length)
  var left, right, constructionStack, candidateHeap: IndexArray
  var output: array[MaxValues, int64]
  for index in 0 ..< n:
    left[index] = length
    right[index] = length

  var stackLength = csize_t(0)
  for index in 0 ..< n:
    var last = length
    while stackLength > 0 and values[constructionStack[stackLength - 1]] > values[index]:
      dec stackLength
      last = constructionStack[stackLength]
    if stackLength > 0:
      right[constructionStack[stackLength - 1]] = csize_t(index)
    if last < length: left[index] = last
    constructionStack[stackLength] = csize_t(index)
    inc stackLength

  var heapLength = csize_t(0)
  pushCandidate(values, candidateHeap, heapLength, constructionStack[0])
  for outputIndex in 0 ..< n:
    let node = popCandidate(values, candidateHeap, heapLength)
    output[outputIndex] = values[node]
    if left[node] < length:
      pushCandidate(values, candidateHeap, heapLength, left[node])
    if right[node] < length:
      pushCandidate(values, candidateHeap, heapLength, right[node])
  for index in 0 ..< n:
    values[index] = output[index]
