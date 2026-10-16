const MaxRequests = 4096
const MaxTrack = 256
const MaxInput = 4100
const FnvOffset = 14695981039346656037'u64
const FnvPrime = 1099511628211'u64

proc hashI64(hashValue: var uint64, value: int64) =
  let bits = cast[uint64](value)
  for shift in countup(0, 56, 8):
    hashValue = (hashValue xor uint64(uint8(bits shr shift))) *% FnvPrime

proc look_scheduling*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "look_scheduling".} =
  if input.isNil or length < 4 or length > csize_t(MaxInput): return -1
  let maxTrack64 = input[0]
  let start64 = input[1]
  let direction = input[2]
  let count64 = input[3]
  if maxTrack64 < 1 or maxTrack64 > MaxTrack or start64 < 0 or start64 >= maxTrack64 or
      (direction != 0 and direction != 1) or count64 < 0 or count64 > MaxRequests or length != csize_t(count64 + 4): return -1
  let maxTrack = int(maxTrack64)
  let start = int(start64)
  let count = int(count64)
  var lowerCounts: array[MaxTrack, int]
  var upperCounts: array[MaxTrack, int]
  var farthest = 0'i64
  for i in 0 ..< count:
    let request = input[4 + i]
    if request < int64(low(int32)) or request > int64(high(int32)): return -1
    if request >= 0 and request < maxTrack64:
      let track = int(request)
      if track < start: inc lowerCounts[track]
      else: inc upperCounts[track]
      if request > farthest: farthest = request

  var route: array[MaxRequests, int64]
  var routeCount = 0
  var track = start
  if direction == 1:
    for ascendingTrack in start ..< maxTrack:
      for _ in 0 ..< upperCounts[ascendingTrack]:
        route[routeCount] = int64(ascendingTrack)
        inc routeCount
    track = start
    while track > 0:
      dec track
      for _ in 0 ..< lowerCounts[track]:
        route[routeCount] = int64(track)
        inc routeCount
  else:
    while track > 0:
      dec track
      for _ in 0 ..< lowerCounts[track]:
        route[routeCount] = int64(track)
        inc routeCount
    for ascendingTrack in start ..< maxTrack:
      for _ in 0 ..< upperCounts[ascendingTrack]:
        route[routeCount] = int64(ascendingTrack)
        inc routeCount

  var hashValue = FnvOffset
  hashI64(hashValue, int64(routeCount))
  for i in 0 ..< routeCount: hashI64(hashValue, route[i])
  let finalDirection = if direction == 1: 0'i64 else: 1'i64
  hashI64(hashValue, finalDirection)
  hashI64(hashValue, farthest)
  hashI64(hashValue, start64)
  int64(hashValue and 0x7fff_ffff_ffff_ffff'u64)
