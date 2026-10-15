## Return unique sorted zero-sum triplets using sort-and-two-pointers.
const MaxItems = 257
const BytesPerTriplet = 12

proc siftDown(values: var array[MaxItems, int64], rootStart, endValue: int) =
  var root = rootStart
  while root < endValue div 2:
    var child = root * 2 + 1
    if child + 1 < endValue and values[child] < values[child + 1]: inc child
    if values[root] >= values[child]: break
    swap(values[root], values[child])
    root = child

proc heapSort(values: var array[MaxItems, int64], length: int) =
  for start in countdown(length div 2 - 1, 0): siftDown(values, start, length)
  for ending in countdown(length - 1, 1):
    swap(values[0], values[ending])
    siftDown(values, 0, ending)

proc storeI32Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint32](int32(value))
  for byte in 0 ..< 4:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255)

proc enumerateTriplets(values: var array[MaxItems, int64], length: int,
    output: ptr UncheckedArray[uint8], writeOutput: bool): int =
  var resultCount = 0
  for first in 0 ..< max(0, length - 2):
    if first > 0 and values[first] == values[first - 1]: continue
    var left = first + 1
    var right = length - 1
    while left < right:
      let sum = values[first] + values[left] + values[right]
      if sum < 0:
        inc left
      elif sum > 0:
        dec right
      else:
        if writeOutput:
          let offset = resultCount * BytesPerTriplet
          storeI32Le(output, offset, values[first])
          storeI32Le(output, offset + 4, values[left])
          storeI32Le(output, offset + 8, values[right])
        inc resultCount
        inc left
        dec right
        while left < right and values[left] == values[left - 1]: inc left
        while left < right and values[right] == values[right + 1]: dec right
  resultCount

proc three_sum*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "three_sum".} =
  if length > csize_t(MaxItems) or (length != 0 and input == nil): return -1
  var values: array[MaxItems, int64]
  for index in 0'u64 ..< uint64(length):
    let value = input[csize_t(index)]
    if value < -100_000 or value > 100_000: return -1
    values[int(index)] = value
  let count = int(length)
  heapSort(values, count)

  let maximumBytes = if count < 2: 0 else: count * (count - 1) div 2 * BytesPerTriplet
  if outputCapacity < csize_t(maximumBytes) or output == nil:
    let needed = enumerateTriplets(values, count, nil, false) * BytesPerTriplet
    if int(outputCapacity) < needed or (needed != 0 and output == nil): return -2
  int64(enumerateTriplets(values, count, output, output != nil))
