const MaxRequests = 64
const MaxOutputValues = 65

proc sortAscending(values: var array[MaxRequests, int32], count: int) =
  for i in 1 ..< count:
    let value = values[i]
    var position = i
    while position > 0 and values[position - 1] > value:
      values[position] = values[position - 1]
      dec position
    values[position] = value

proc putI32Le(output: ptr UncheckedArray[uint8], offset: int, value: int32) =
  let bits = cast[uint32](value)
  for byte in 0 ..< 4:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc scan_scheduling*(input: ptr UncheckedArray[int32], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "scan_scheduling".} =
  if input == nil or length < 4 or length > 68: return -1
  let diskSize = input[0]
  let head = input[1]
  let direction = input[2]
  let requestCount = input[3]
  if diskSize < 1 or diskSize > 256 or head < 0 or head >= diskSize or
      (direction != 0 and direction != 1) or requestCount < 0 or requestCount > MaxRequests or
      length != csize_t(4 + requestCount): return -1

  var left, right: array[MaxRequests, int32]
  var leftCount, rightCount = 0
  for i in 0 ..< int(requestCount):
    let request = input[4 + i]
    if request < 0 or request >= diskSize: return -1
    if request < head:
      left[leftCount] = request
      inc leftCount
    else:
      right[rightCount] = request
      inc rightCount
  sortAscending(left, leftCount)
  sortAscending(right, rightCount)

  var ordered: array[MaxOutputValues, int32]
  var count = 0
  if requestCount > 0:
    if direction == 1:
      for i in 0 ..< rightCount:
        ordered[count] = right[i]
        inc count
      ordered[count] = diskSize - 1
      inc count
      var i = leftCount
      while i > 0:
        dec i
        ordered[count] = left[i]
        inc count
    else:
      var i = leftCount
      while i > 0:
        dec i
        ordered[count] = left[i]
        inc count
      ordered[count] = 0
      inc count
      for i in 0 ..< rightCount:
        ordered[count] = right[i]
        inc count

  let bytes = count * 4
  if output == nil or capacity < csize_t(bytes): return -2
  for i in 0 ..< count: putI32Le(output, i * 4, ordered[i])
  int64(bytes)
