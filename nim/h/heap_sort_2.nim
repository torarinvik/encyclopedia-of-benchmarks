const MaxValues = 1024

proc siftUp(values: ptr UncheckedArray[int64], indexValue: int) =
  var index = indexValue
  while index > 0:
    let parent = (index - 1) div 2
    if values[parent] >= values[index]: break
    swap(values[parent], values[index])
    index = parent

proc siftDown(values: ptr UncheckedArray[int64], size: int) =
  var root = 0
  while root < size div 2:
    let left = root * 2 + 1
    var largest = left
    let right = left + 1
    if right < size and values[right] > values[left]: largest = right
    if values[root] >= values[largest]: break
    swap(values[root], values[largest])
    root = largest

proc heap_sort_2*(values: ptr UncheckedArray[int64], length: csize_t)
    {.cdecl, exportc: "heap_sort_2".} =
  if length > csize_t(MaxValues): return
  let n = int(length)
  for index in 0 ..< n: siftUp(values, index)
  for size in countdown(n, 2):
    swap(values[0], values[size - 1])
    siftDown(values, size - 1)
