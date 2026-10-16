const MaxLists = 8
const MaxChainLength = 8
const MaxTotalValues = MaxLists * MaxChainLength
const MaxInputLength = 1 + MaxLists * (1 + MaxChainLength)

proc mergeRecursive(left: ptr UncheckedArray[int64], leftLength, leftIndex: int,
                    right: ptr UncheckedArray[int64], rightLength, rightIndex: int,
                    output: ptr UncheckedArray[int64], outputIndex: int): int =
  if leftIndex == leftLength:
    let remaining = rightLength - rightIndex
    for i in 0 ..< remaining: output[outputIndex + i] = right[rightIndex + i]
    return outputIndex + remaining
  if rightIndex == rightLength:
    let remaining = leftLength - leftIndex
    for i in 0 ..< remaining: output[outputIndex + i] = left[leftIndex + i]
    return outputIndex + remaining
  if left[leftIndex] < right[rightIndex]:
    output[outputIndex] = left[leftIndex]
    return mergeRecursive(left, leftLength, leftIndex + 1, right, rightLength,
      rightIndex, output, outputIndex + 1)
  output[outputIndex] = right[rightIndex]
  mergeRecursive(left, leftLength, leftIndex, right, rightLength,
    rightIndex + 1, output, outputIndex + 1)

proc flattenSuffix(lists: ptr UncheckedArray[int64], lengths: ptr UncheckedArray[int],
                   count, index: int, output: ptr UncheckedArray[int64]): int =
  let row = index * MaxChainLength
  if index + 1 == count:
    for i in 0 ..< lengths[index]: output[i] = lists[row + i]
    return lengths[index]
  var suffix: array[MaxTotalValues, int64]
  let suffixLength = flattenSuffix(lists, lengths, count, index + 1, addr suffix[0])
  mergeRecursive(addr lists[row], lengths[index], 0, addr suffix[0], suffixLength, 0, output, 0)

proc storeI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc flatten_multilevel_linked_list*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc.} =
  if values == nil or length < 1 or length > csize_t(MaxInputLength): return -1
  if values[0] < 0 or values[0] > MaxLists: return -1
  let count = int(values[0])
  if count == 0: return if length == 1: 0 else: -1

  var lists: array[MaxLists * MaxChainLength, int64]
  var lengths: array[MaxLists, int]
  var total = 0
  var cursor = 1
  let inputLength = int(length)
  for list in 0 ..< count:
    if cursor >= inputLength or values[cursor] < 1 or values[cursor] > MaxChainLength: return -1
    let chainLength = int(values[cursor])
    inc cursor
    if chainLength > inputLength - cursor: return -1
    lengths[list] = chainLength
    let row = list * MaxChainLength
    for item in 0 ..< chainLength:
      let value = values[cursor]
      inc cursor
      if value < -1000 or value > 1000 or
          (item > 0 and value < lists[row + item - 1]): return -1
      lists[row + item] = value
    total += chainLength
  if cursor != inputLength: return -1
  let required = csize_t(total * 8)
  if output == nil or capacity < required: return -2

  var flattened: array[MaxTotalValues, int64]
  discard flattenSuffix(addr lists[0], addr lengths[0], count, 0, addr flattened[0])
  for i in 0 ..< total: storeI64(output, 8 * i, flattened[i])
  int64(total)
