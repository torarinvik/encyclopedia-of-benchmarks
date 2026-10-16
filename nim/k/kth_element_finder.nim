const InvalidResult = low(int64)

proc siftDown(heap: var array[256, int64], heapSize, root0: int, minHeap: bool) =
  var root = root0
  while true:
    var best = root
    let left = root * 2 + 1
    let right = left + 1
    if left < heapSize:
      if (minHeap and heap[left] < heap[best]) or (not minHeap and heap[left] > heap[best]):
        best = left
    if right < heapSize:
      if (minHeap and heap[right] < heap[best]) or (not minHeap and heap[right] > heap[best]):
        best = right
    if best == root: break
    swap(heap[root], heap[best])
    root = best

proc kth_element_finder*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "kth_element_finder".} =
  if input.isNil or length < 4 or length > 259: return InvalidResult
  let mode = input[0]
  let nValue = input[1]
  let kValue = input[2]
  if (mode != 0 and mode != 1) or nValue < 1 or nValue > 256 or kValue < 1 or kValue > nValue:
    return InvalidResult
  let n = int(nValue)
  let k = int(kValue)
  if int(length) != n + 3: return InvalidResult
  for i in 0 ..< n:
    if input[i + 3] < -1_000_000 or input[i + 3] > 1_000_000: return InvalidResult

  let minHeap = mode == 0
  var heap: array[256, int64]
  for i in 0 ..< k: heap[i] = input[i + 3]
  var start = k div 2
  while start > 0:
    dec start
    siftDown(heap, k, start, minHeap)
  for i in k ..< n:
    let value = input[i + 3]
    if (minHeap and value > heap[0]) or (not minHeap and value < heap[0]):
      heap[0] = value
      siftDown(heap, k, 0, minHeap)
  heap[0]
