const MaxCount = 64
const MaxInputLength = 66

proc sift(values: var array[MaxCount, int64], rootArg, orderArg: int, leonardo: array[16, int]) =
  var root = rootArg; var order = orderArg
  while order > 1:
    let right = root - 1; let left = root - 1 - leonardo[order - 2]
    if not (values[left] < values[right]) and values[root] < values[left]:
      swap(values[root], values[left]); root = left; dec order
    elif values[left] < values[right] and values[root] < values[right]:
      swap(values[root], values[right]); root = right; order -= 2
    else: break

proc trinkle(values: var array[MaxCount, int64], positionArg: int,
             orders: var array[MaxCount, int], indexArg: int,
             leonardo: array[16, int]) =
  var position = positionArg; var index = indexArg
  while index > 0:
    let previous = position - leonardo[orders[index]]
    if not (values[position] < values[previous]): break
    if orders[index] > 1:
      let right = position - 1; let left = position - 1 - leonardo[orders[index] - 2]
      if not (values[right] < values[previous]) or not (values[left] < values[previous]): break
    swap(values[position], values[previous]); position = previous; dec index
  sift(values, position, orders[index], leonardo)

proc smoothSort(values: var array[MaxCount, int64], count: int) =
  if count < 2: return
  var leonardo: array[16, int]; leonardo[0] = 1; leonardo[1] = 1
  for i in 2 ..< 16: leonardo[i] = leonardo[i - 1] + leonardo[i - 2] + 1
  var orders: array[MaxCount, int]; var heapCount = 0
  for position in 0 ..< count:
    if heapCount >= 2 and orders[heapCount - 2] == orders[heapCount - 1] + 1:
      dec heapCount; inc orders[heapCount - 1]
    elif heapCount > 0 and orders[heapCount - 1] == 1:
      orders[heapCount] = 0; inc heapCount
    else:
      orders[heapCount] = 1; inc heapCount
    trinkle(values, position, orders, heapCount - 1, leonardo)
  for position in countdown(count - 1, 0):
    dec heapCount; let order = orders[heapCount]
    if order > 1:
      let rightOrder = order - 2; let leftOrder = order - 1
      let rightPosition = position - 1; let leftPosition = position - 1 - leonardo[rightOrder]
      orders[heapCount] = leftOrder; inc heapCount
      trinkle(values, leftPosition, orders, heapCount - 1, leonardo)
      orders[heapCount] = rightOrder; inc heapCount
      trinkle(values, rightPosition, orders, heapCount - 1, leonardo)

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc smoothsort*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "smoothsort".} =
  if input.isNil or inputLength < csize_t(1) or inputLength > csize_t(MaxInputLength): return -1
  if input[0] < 0 or input[0] > int64(MaxCount): return -1
  let count = int(input[0])
  if int(inputLength) != 1 + count or inputLength > csize_t(MaxCount + 1): return -1
  var values: array[MaxCount, int64]
  for i in 0 ..< count: values[i] = input[i + 1]
  smoothSort(values, count)
  let bytes = csize_t(count * 8)
  if output.isNil or outputCapacity < bytes: return -2
  for i in 0 ..< count: storeI64Le(output, i * 8, values[i])
  int64(bytes)
