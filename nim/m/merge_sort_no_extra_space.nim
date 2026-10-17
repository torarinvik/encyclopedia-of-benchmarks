const MaxLength = 256

proc readI32Le(buffer: ptr UncheckedArray[uint8], index: int): int32 =
  let offset = index * 4
  let bits = uint32(buffer[offset]) or (uint32(buffer[offset + 1]) shl 8) or
    (uint32(buffer[offset + 2]) shl 16) or (uint32(buffer[offset + 3]) shl 24)
  cast[int32](bits)

proc writeI32Le(buffer: ptr UncheckedArray[uint8], index: int, value: int32) =
  let bits = cast[uint32](value)
  let offset = index * 4
  for byte in 0 ..< 4:
    buffer[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u32)

proc merge(buffer: ptr UncheckedArray[uint8], start, middle, finish: int, maxElement: int32) =
  var i = start
  var j = middle + 1
  var k = start
  while i <= middle and j <= finish:
    let left = readI32Le(buffer, i) mod maxElement
    let right = readI32Le(buffer, j) mod maxElement
    let current = readI32Le(buffer, k)
    if left <= right:
      writeI32Le(buffer, k, current + left * maxElement)
      inc i
    else:
      writeI32Le(buffer, k, current + right * maxElement)
      inc j
    inc k
  while i <= middle:
    let current = readI32Le(buffer, k)
    let next = readI32Le(buffer, i) mod maxElement
    writeI32Le(buffer, k, current + next * maxElement)
    inc i
    inc k
  while j <= finish:
    let current = readI32Le(buffer, k)
    let next = readI32Le(buffer, j) mod maxElement
    writeI32Le(buffer, k, current + next * maxElement)
    inc j
    inc k
  for index in start .. finish:
    writeI32Le(buffer, index, readI32Le(buffer, index) div maxElement)

proc mergeSort(buffer: ptr UncheckedArray[uint8], start, finish: int, maxElement: int32) =
  if start >= finish: return
  let middle = start + (finish - start) div 2
  mergeSort(buffer, start, middle, maxElement)
  mergeSort(buffer, middle + 1, finish, maxElement)
  merge(buffer, start, middle, finish, maxElement)

proc merge_sort_no_extra_space*(values: ptr UncheckedArray[int32], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "merge_sort_no_extra_space".} =
  if values == nil or length > csize_t(MaxLength): return -1
  let n = int(length)
  var maxValue = 0'i32
  for index in 0 ..< n:
    if values[index] < 0 or values[index] > 32767: return -1
    maxValue = max(maxValue, values[index])
  let outputBytes = n * 4
  if output == nil or outputCapacity < csize_t(outputBytes): return -2
  for index in 0 ..< n: writeI32Le(output, index, values[index])
  if n > 1: mergeSort(output, 0, n - 1, maxValue + 1)
  int64(outputBytes)
