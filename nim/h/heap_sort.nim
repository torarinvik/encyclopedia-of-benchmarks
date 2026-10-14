## In-place max-heap sort with a zero-based heap.
proc siftDown(values: ptr UncheckedArray[int64], root, end: csize_t) =
  var current = root
  while current < end div 2:
    var child = current * 2 + 1
    if child + 1 < end and values[child] < values[child + 1]:
      inc child
    if values[current] >= values[child]:
      break
    swap(values[current], values[child])
    current = child

proc heap_sort*(values: ptr UncheckedArray[int64], length: csize_t) {.cdecl, exportc: "heap_sort".} =
  var start = length div 2
  while start > 0:
    dec start
    siftDown(values, start, length)
  var end = length
  while end > 1:
    dec end
    swap(values[0], values[end])
    siftDown(values, 0, end)
