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

proc wiggle_sort_strict*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "wiggle_sort_strict".} =
  if length > csize_t(MaxArrayLength) or (length != 0 and input == nil): return -1
  let count = int(length)
  var values: array[MaxArrayLength, int64]

  for i in 0 ..< count:
    let value = input[csize_t(i)]
    if value < int64(low(int32)) or value > int64(high(int32)): return -1
    values[i] = value
  let byteCount = count * 4
  if outputCapacity < csize_t(byteCount) or (byteCount != 0 and output == nil): return -2
  if count == 0: return 0

  let median = selectKth(values, count, count div 2)
  var medianCount = 0
  var smallestValue = values[0]
  for i in 0 ..< count:
    if values[i] == median: inc medianCount
    if values[i] < smallestValue: smallestValue = values[i]
  let maximumMedians = (count + 1) div 2
  if medianCount > maximumMedians or
      (count mod 2 == 1 and medianCount == maximumMedians and smallestValue != median):
    return -1

  var i = 0
  var j = 0
  var k = count - 1
  let modulus = count + 1 - (count mod 2)
  while j <= k:
    let mappedJ = (2 * j + 1) mod modulus
    if values[mappedJ] > median:
      let mappedI = (2 * i + 1) mod modulus
      swap(values[mappedJ], values[mappedI])
      inc i
      inc j
    elif values[mappedJ] < median:
      let mappedK = (2 * k + 1) mod modulus
      swap(values[mappedJ], values[mappedK])
      dec k
    else:
      inc j
  for i in 0 ..< count:
    storeI32Le(output, i * 4, values[i])
  int64(count)
