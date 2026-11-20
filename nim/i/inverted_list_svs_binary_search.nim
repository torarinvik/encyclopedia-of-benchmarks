const MinLists = 2
const MaxLists = 8
const MaxListLength = 32
const MaxInputLength = 266
const BytesPerValue = 4

proc storeI32Le(output: ptr UncheckedArray[uint8], position: int, value: int32) =
  let bits = cast[uint32](value)
  for byte in 0 ..< BytesPerValue:
    output[position + byte] = uint8((bits shr (byte * 8)) and 255)

proc inverted_list_svs_binary_search*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "inverted_list_svs_binary_search".} =
  if input == nil or length < csize_t(MinLists + 1) or length > csize_t(MaxInputLength): return -1
  if input[0] < int64(MinLists) or input[0] > int64(MaxLists): return -1
  let count = int(input[0])
  var starts, sizes, order: array[MaxLists, int]
  var position = 1
  for list in 0 ..< count:
    if position >= int(length) or input[position] < 0 or input[position] > int64(MaxListLength): return -1
    let size = int(input[position]); inc position
    if size > int(length) - position: return -1
    starts[list] = position; sizes[list] = size; order[list] = list
    for i in 0 ..< size:
      let value = input[position + i]
      if value < int64(low(int32)) or value > int64(high(int32)): return -1
      if i > 0 and input[position + i - 1] >= value: return -1
    position += size
  if position != int(length): return -1
  for i in 1 ..< count:
    let key = order[i]
    var j = i
    while j > 0 and sizes[order[j - 1]] > sizes[key]:
      order[j] = order[j - 1]; dec j
    order[j] = key
  let maximumResult = sizes[order[0]]
  if outputCapacity < csize_t(maximumResult * BytesPerValue) or (maximumResult > 0 and output == nil): return -2
  var candidates: array[MaxListLength, int32]
  var candidateCount = maximumResult
  for i in 0 ..< candidateCount: candidates[i] = int32(input[starts[order[0]] + i])
  for rank in 1 ..< count:
    if candidateCount == 0: break
    let list = order[rank]; let start = starts[list]; let size = sizes[list]
    var cursor = 0; var kept = 0
    for i in 0 ..< candidateCount:
      let candidate = candidates[i]
      var low = cursor; var high = size
      while low < high:
        let middle = low + (high - low) div 2
        if input[start + middle] < int64(candidate): low = middle + 1 else: high = middle
      if low < size and input[start + low] == int64(candidate):
        candidates[kept] = candidate; inc kept; cursor = low + 1
      else: cursor = low
    candidateCount = kept
  for i in 0 ..< candidateCount: storeI32Le(output, i * BytesPerValue, candidates[i])
  int64(candidateCount)
