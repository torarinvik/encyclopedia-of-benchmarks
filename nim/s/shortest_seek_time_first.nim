const MaxRequests = 64

proc shortest_seek_time_first*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "shortest_seek_time_first".} =
  if values == nil or length < 2 or length > csize_t(2 + MaxRequests): return -1
  let initialTrack = values[0]
  let requestCount = values[1]
  if initialTrack < 0 or initialTrack > 255 or requestCount < 0 or requestCount > int64(MaxRequests) or
      length != csize_t(2 + requestCount): return -1
  for i in 0 ..< int(requestCount):
    let request = values[2 + i]
    if request < 0 or request > 255: return -1
  if output == nil or outputCapacity < csize_t(requestCount): return -2

  var serviced: array[MaxRequests, bool]
  var current = initialTrack
  for step in 0 ..< int(requestCount):
    var best = MaxRequests
    var bestDistance = 256'i64
    for i in 0 ..< int(requestCount):
      if serviced[i]: continue
      var distance = current - values[2 + i]
      if distance < 0: distance = -distance
      if distance < bestDistance:
        best = i
        bestDistance = distance
    let selected = values[2 + best]
    output[step] = uint8(selected)
    serviced[best] = true
    current = selected
  requestCount
