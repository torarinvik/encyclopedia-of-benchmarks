const InvalidResult = low(int64)
const MaxValues = 1024

proc find_kth_number*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "find_kth_number".} =
  if values == nil or length < 2 or length > csize_t(MaxValues + 1): return InvalidResult
  let k = values[0]
  let count = int(length) - 1
  if k < 1 or k > int64(count): return InvalidResult
  var heap: array[MaxValues, int32]
  for i in 0 ..< count:
    let input = values[i + 1]
    if input < -2_147_483_648'i64 or input > 2_147_483_647'i64: return InvalidResult
    var index = i
    heap[index] = int32(input)
    while index > 0:
      let parent = (index - 1) div 2
      if heap[parent] >= heap[index]: break
      swap(heap[parent], heap[index])
      index = parent
  var heapSize = count
  for removed in 1 ..< int(k):
    dec heapSize
    heap[0] = heap[heapSize]
    var index = 0
    while index * 2 + 1 < heapSize:
      var child = index * 2 + 1
      if child + 1 < heapSize and heap[child + 1] > heap[child]: inc child
      if heap[index] >= heap[child]: break
      swap(heap[index], heap[child])
      index = child
  int64(heap[0])
