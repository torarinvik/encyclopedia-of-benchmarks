const MaxRequests = 64
const MaxCylinderCount = 128'i64

proc sortAscending(items: var array[MaxRequests, int64], count: int) =
  for index in 1 ..< count:
    let value = items[index]
    var position = index
    while position > 0 and items[position - 1] > value:
      items[position] = items[position - 1]
      dec position
    items[position] = value

proc circular_scan_scheduling*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "circular_scan_scheduling".} =
  if values == nil or length < 4 or length > csize_t(4 + MaxRequests): return -1
  let maxCylinder = values[0]
  let start = values[1]
  let movingUp = values[2]
  let requestCount = values[3]
  if maxCylinder < 1 or maxCylinder > MaxCylinderCount or start < 0 or start >= maxCylinder or
      (movingUp != 0 and movingUp != 1) or requestCount < 0 or requestCount > int64(MaxRequests) or
      length != csize_t(4 + requestCount): return -1

  var up, down: array[MaxRequests, int64]
  var upCount, downCount = 0
  for index in 0 ..< int(requestCount):
    let request = values[4 + index]
    if request < -128 or request > 127: return -1
    if movingUp == 1:
      if request >= start and request < maxCylinder:
        up[upCount] = request
        inc upCount
      elif request < start:
        down[downCount] = request
        inc downCount
    else:
      if request <= start:
        down[downCount] = request
        inc downCount
      else:
        up[upCount] = request
        inc upCount
  sortAscending(up, upCount)
  sortAscending(down, downCount)

  let outputCount = upCount + downCount
  if outputCapacity < csize_t(outputCount) or (outputCount > 0 and output == nil): return -2
  var position = 0
  if movingUp == 1:
    for index in 0 ..< upCount:
      output[position] = uint8((up[index] + 256) mod 256)
      inc position
    for index in 0 ..< downCount:
      output[position] = uint8((down[index] + 256) mod 256)
      inc position
  else:
    var index = downCount
    while index > 0:
      dec index
      output[position] = uint8((down[index] + 256) mod 256)
      inc position
    index = upCount
    while index > 0:
      dec index
      output[position] = uint8((up[index] + 256) mod 256)
      inc position
  int64(outputCount)
