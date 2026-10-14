## Introsort with quicksort partitioning, a heapsort depth fallback, and insertion cutoff.
proc swap_i64(values: ptr UncheckedArray[int64], left, right: csize_t) =
  let temporary = values[left]
  values[left] = values[right]
  values[right] = temporary

proc insertion_sort_range(values: ptr UncheckedArray[int64], low, high: csize_t) =
  var index = low + 1
  while index < high:
    let key = values[index]
    var cursor = index
    while cursor > low and values[cursor - 1] > key:
      values[cursor] = values[cursor - 1]
      dec cursor
    values[cursor] = key
    inc index

proc sift_down(values: ptr UncheckedArray[int64], start, count, root_start: csize_t) =
  var root = root_start
  while root < count div 2:
    var child = root * 2 + 1
    if child + 1 < count and values[start + child] < values[start + child + 1]:
      inc child
    if values[start + root] >= values[start + child]:
      return
    swap_i64(values, start + root, start + child)
    root = child

proc heap_sort_range(values: ptr UncheckedArray[int64], low, count: csize_t) =
  var parent = count div 2
  while parent > 0:
    dec parent
    sift_down(values, low, count, parent)
  var ending = count
  while ending > 1:
    dec ending
    swap_i64(values, low, low + ending)
    sift_down(values, low, ending, 0)

proc partition_range(values: ptr UncheckedArray[int64], low, high: csize_t): csize_t =
  let last = high - 1
  let pivotIndex = low + (high - low) div 2
  swap_i64(values, pivotIndex, last)
  let pivot = values[last]
  var boundary = low
  var probe = low
  while probe < last:
    if values[probe] <= pivot:
      swap_i64(values, boundary, probe)
      inc boundary
    inc probe
  swap_i64(values, boundary, last)
  return boundary

proc intro_sort_range(values: ptr UncheckedArray[int64], low, high, depth: csize_t) =
  let count = high - low
  if count <= 16:
    insertion_sort_range(values, low, high)
    return
  if depth == 0:
    heap_sort_range(values, low, count)
    return
  let pivot = partition_range(values, low, high)
  intro_sort_range(values, low, pivot, depth - 1)
  intro_sort_range(values, pivot + 1, high, depth - 1)

proc depth_limit(length: csize_t): csize_t =
  var remaining = length
  var logarithm = csize_t(0)
  while remaining > 1:
    remaining = remaining div 2
    inc logarithm
  return logarithm * 2

proc intro_sort*(values: ptr UncheckedArray[int64], length: csize_t) {.cdecl, exportc: "intro_sort".} =
  if length < 2:
    return
  intro_sort_range(values, 0, length, depth_limit(length))
