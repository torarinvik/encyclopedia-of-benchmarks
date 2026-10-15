## Sort a bounded copy and emit sorted duplicate values as little-endian i32s.
const MaxLength = 100_000

proc siftDown(values: ptr UncheckedArray[int32], rootValue, endExclusive: csize_t) =
  var root = rootValue
  while root * 2 + 1 < endExclusive:
    var child = root * 2 + 1
    if child + 1 < endExclusive and values[child] < values[child + 1]: inc child
    if values[root] >= values[child]: break
    swap(values[root], values[child])
    root = child

proc heapSort(values: ptr UncheckedArray[int32], length: csize_t) =
  var start = length div 2
  while start > 0:
    dec start
    siftDown(values, start, length)
  var ending = length
  while ending > 1:
    dec ending
    swap(values[0], values[ending])
    siftDown(values, 0, ending)

proc find_all_duplicates_in_array*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "find_all_duplicates_in_array".} =
  if length > csize_t(MaxLength) or (length != 0 and values.isNil): return -1
  if length == 0: return 0

  var sorted: array[MaxLength, int32]
  for index in 0 ..< int(length):
    if values[index] < 1 or values[index] > int64(length): return -1
    sorted[index] = int32(values[index])
  heapSort(cast[ptr UncheckedArray[int32]](addr sorted[0]), length)

  var duplicateCount = 0
  var index = 0
  while index < int(length):
    var ending = index + 1
    while ending < int(length) and sorted[ending] == sorted[index]: inc ending
    let frequency = ending - index
    if frequency > 2: return -1
    if frequency == 2: inc duplicateCount
    index = ending
  let outputBytes = csize_t(duplicateCount * 4)
  if outputCapacity < outputBytes or (outputBytes != 0 and output.isNil): return -2

  var destination = 0
  index = 0
  while index < int(length):
    var ending = index + 1
    while ending < int(length) and sorted[ending] == sorted[index]: inc ending
    if ending - index == 2:
      let value = uint32(sorted[index])
      for byte in 0 ..< 4:
        output[destination * 4 + byte] = uint8((value shr (byte * 8)) and 255)
      inc destination
    index = ending
  int64(duplicateCount)
