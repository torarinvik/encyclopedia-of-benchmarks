## Return the encoded narrowest interval that covers all sorted input lists.
proc lessHead(values: array[16, array[16, int64]], positions: array[16, int], a, b: int): bool =
  let left = values[a][positions[a]]
  let right = values[b][positions[b]]
  left < right or (left == right and a < b)

proc smallest_range*(packed: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "smallest_range".} =
  if packed.isNil or length < 2 or length > 273: return -1
  if packed[0] < 1 or packed[0] > 16: return -1
  let count = int(packed[0])
  var values: array[16, array[16, int64]]
  var lengths, positions, heap: array[16, int]
  var offset = 1
  var total = 0
  var currentMax = -1_000_000_001'i64
  for i in 0 ..< count:
    if offset >= int(length) or packed[offset] < 1 or packed[offset] > 16: return -1
    lengths[i] = int(packed[offset]); inc offset
    if lengths[i] > 256 - total or offset + lengths[i] > int(length): return -1
    total += lengths[i]
    for j in 0 ..< lengths[i]:
      let value = packed[offset]; inc offset
      if value < -1_000_000_000 or value > 1_000_000_000 or (j > 0 and value < values[i][j - 1]): return -1
      values[i][j] = value
    heap[i] = i
    currentMax = max(currentMax, values[i][0])
  if offset != int(length): return -1
  let heapSize = count
  for start in countdown(heapSize div 2 - 1, 0):
    var root = start
    while true:
      var child = root * 2 + 1
      if child >= heapSize: break
      if child + 1 < heapSize and lessHead(values, positions, heap[child + 1], heap[child]): inc child
      if not lessHead(values, positions, heap[child], heap[root]): break
      swap(heap[root], heap[child]); root = child
  var bestLo = 0'i64
  var bestHi = 0'i64
  var bestWidth = high(int64)
  while true:
    let list = heap[0]
    let lo = values[list][positions[list]]
    let width = currentMax - lo
    if width < bestWidth:
      bestWidth = width; bestLo = lo; bestHi = currentMax
    inc positions[list]
    if positions[list] == lengths[list]: break
    currentMax = max(currentMax, values[list][positions[list]])
    var root = 0
    while true:
      var child = root * 2 + 1
      if child >= heapSize: break
      if child + 1 < heapSize and lessHead(values, positions, heap[child + 1], heap[child]): inc child
      if not lessHead(values, positions, heap[child], heap[root]): break
      swap(heap[root], heap[child]); root = child
  (bestLo + 1_000_000_000) * 2_000_000_001 + bestHi + 1_000_000_000
