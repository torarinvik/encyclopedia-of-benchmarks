const MaxItems = 128

proc mergeSort(items: var array[MaxItems, int32], scratch: var array[MaxItems, int32], count: int) =
  var width = 1
  while width < count:
    var start = 0
    while start < count:
      let middle = min(start + width, count)
      let finish = min(middle + width, count)
      var left = start
      var right = middle
      var outIndex = start
      while left < middle and right < finish:
        if items[left] <= items[right]:
          scratch[outIndex] = items[left]
          inc left
        else:
          scratch[outIndex] = items[right]
          inc right
        inc outIndex
      while left < middle:
        scratch[outIndex] = items[left]
        inc left
        inc outIndex
      while right < finish:
        scratch[outIndex] = items[right]
        inc right
        inc outIndex
      start = finish
    for i in 0 ..< count: items[i] = scratch[i]
    width *= 2

proc insertionSort(items: var array[MaxItems, int32], count: int) =
  for i in 1 ..< count:
    let value = items[i]
    var j = i
    while j > 0 and items[j - 1] > value:
      items[j] = items[j - 1]
      dec j
    items[j] = value

proc siftDown(items: var array[MaxItems, int32], count: int, initialRoot: int) =
  var root = initialRoot
  while root < count div 2:
    var child = 2 * root + 1
    if child + 1 < count and items[child + 1] > items[child]: inc child
    if items[root] >= items[child]: return
    swap(items[root], items[child])
    root = child

proc heapSort(items: var array[MaxItems, int32], count: int) =
  if count < 2: return
  for start in countdown(count div 2 - 1, 0): siftDown(items, count, start)
  for endIndex in countdown(count - 1, 1):
    swap(items[0], items[endIndex])
    siftDown(items, endIndex, 0)

proc link_list_sort*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "link_list_sort".} =
  if input == nil or length < 2 or length > 130: return -1
  let selector = input[0]
  let countValue = input[1]
  if selector < 1 or selector > 3 or countValue < 0 or countValue > MaxItems: return -1
  let count = int(countValue)
  if length != csize_t(2 + count): return -1
  var items: array[MaxItems, int32]
  var scratch: array[MaxItems, int32]
  for i in 0 ..< count:
    if input[2 + i] < int64(low(int32)) or input[2 + i] > int64(high(int32)): return -1
    items[i] = int32(input[2 + i])
  case selector
  of 1: mergeSort(items, scratch, count)
  of 2: insertionSort(items, count)
  else: heapSort(items, count)
  let required = 4 * count
  if output == nil or outputCapacity < csize_t(required): return -2
  for i in 0 ..< count:
    var bits = cast[uint32](items[i])
    for byte in 0 ..< 4:
      output[4 * i + byte] = uint8(bits and 255)
      bits = bits shr 8
  int64(required)
