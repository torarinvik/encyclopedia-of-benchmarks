## Bottom-up merge passes over two bounded buffers, modeling sequential stores.
const MaxValues = 4096

proc mergePass(source, destination: ptr UncheckedArray[int64], length, width: int) =
  var start = 0
  while start < length:
    let middle = min(start + width, length)
    let finish = min(middle + width, length)
    var left = start
    var right = middle
    var output = start
    while left < middle and right < finish:
      if source[left] < source[right]:
        destination[output] = source[left]
        inc left
      else:
        destination[output] = source[right]
        inc right
      inc output
    while left < middle:
      destination[output] = source[left]
      inc left
      inc output
    while right < finish:
      destination[output] = source[right]
      inc right
      inc output
    start += width * 2

proc external_merge_sorter*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "external_merge_sorter".} =
  if length > csize_t(MaxValues) or (length != 0 and values == nil): return -1
  let n = int(length)
  let outputBytes = n * 8
  if output == nil or outputCapacity < csize_t(outputBytes): return -2

  var primary: array[MaxValues, int64]
  var temporary: array[MaxValues, int64]
  for index in 0 ..< n: primary[index] = values[csize_t(index)]
  var source = cast[ptr UncheckedArray[int64]](addr primary[0])
  var destination = cast[ptr UncheckedArray[int64]](addr temporary[0])
  var width = 1
  while width < n:
    mergePass(source, destination, n, width)
    swap(source, destination)
    if width > n div 2: break
    width *= 2
  for index in 0 ..< n:
    let bits = cast[uint64](source[index])
    for byte in 0 ..< 8:
      output[csize_t(index * 8 + byte)] = uint8((bits shr (byte * 8)) and 255'u64)
  int64(outputBytes)
