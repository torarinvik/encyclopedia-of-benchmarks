const MaxArrayLength = 4096

proc selectKth(values: var array[MaxArrayLength, int64], count, target: int): int64 =
  var low = 0
  var high = count - 1
  while low < high:
    var left = low
    var right = high
    let pivot = values[(left + right + 1) div 2]
    while left <= right:
      while left <= right and values[left] < pivot: inc left
      while left <= right and values[right] > pivot: dec right
      if left <= right:
        swap(values[left], values[right])
        inc left
        dec right
    if target <= right: high = right
    elif target >= left: low = left
    else: break
  values[target]

proc storeI32Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint32](int32(value))
  for byte in 0 ..< 4:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255)

proc simplified_wiggle_sort*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "simplified_wiggle_sort".} =
  if length > csize_t(MaxArrayLength) or (length != 0 and input == nil): return -1
  let count = int(length)
  var values: array[MaxArrayLength, int64]
  var ordered: array[MaxArrayLength, int64]
  for i in 0 ..< count:
    let value = input[csize_t(i)]
    if value < int64(low(int32)) or value > int64(high(int32)): return -1
    values[i] = value
  let byteCount = count * 4
  if outputCapacity < csize_t(byteCount) or (byteCount != 0 and output == nil): return -2
  if count == 0: return 0

  let median = selectKth(values, count, count div 2)
  var smaller = 0
  var greater = count - 1 - (count mod 2)
  for i in 0 ..< count:
    if values[i] > median:
      ordered[greater] = values[i]
      greater -= 2
    elif smaller < count:
      ordered[smaller] = values[i]
      smaller += 2
    else:
      ordered[greater] = values[i]
      greater -= 2
  for i in 0 ..< count:
    storeI32Le(output, i * 4, ordered[i])
  int64(count)
