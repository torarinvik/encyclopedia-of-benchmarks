proc putI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255'u64)

proc siftDown(values: var openArray[int64], rootStart, ending: int) =
  var root = rootStart
  while root < ending div 2:
    var child = root * 2 + 1
    if child + 1 < ending and values[child] < values[child + 1]: inc child
    if values[root] >= values[child]: break
    swap(values[root], values[child])
    root = child

proc heapSort(values: var openArray[int64]) =
  for start in countdown(values.len div 2, 1):
    siftDown(values, start - 1, values.len)
  for ending in countdown(values.len, 2):
    swap(values[0], values[ending - 1])
    siftDown(values, 0, ending - 1)

proc triplet_sum_two_pointer*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "triplet_sum_two_pointer".} =
  const MaxItems = 1024
  if input == nil or length < 1 or length > MaxItems + 1: return -1
  let target = input[0]
  if target < -3_000_000 or target > 3_000_000: return -1
  let itemCount = int(length - 1)
  var values: array[MaxItems, int64]
  for index in 0 ..< itemCount:
    let value = input[index + 1]
    if value < -1_000_000 or value > 1_000_000: return -1
    values[index] = value
  if outputCapacity < 24 or output == nil: return -2
  if itemCount > 1: heapSort(values.toOpenArray(0, itemCount - 1))

  var result = [0'i64, 0'i64, 0'i64]
  if itemCount >= 3:
    for first in 0 ..< itemCount - 2:
      var left = first + 1
      var right = itemCount - 1
      while left < right:
        let sum = values[first] + values[left] + values[right]
        if sum == target:
          result = [values[first], values[left], values[right]]
          for index in 0 ..< 3: putI64Le(output, index * 8, result[index])
          return 3
        if sum < target: inc left else: dec right
  for index in 0 ..< 3: putI64Le(output, index * 8, result[index])
  3
