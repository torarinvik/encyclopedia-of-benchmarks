const MaxRequests = 7
const MaxFiles = 8
const MaxInput = 16

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc greedy_dual_weighted_caching*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "greedy_dual_weighted_caching".} =
  if input == nil or length < 2 or length > csize_t(MaxInput): return -1
  let cacheCapacity, countValue = input[0], input[1]
  if cacheCapacity < 1 or cacheCapacity > MaxFiles or countValue < 0 or countValue > MaxRequests or
      int(length) != 2 + 2 * int(countValue): return -1
  var knownCost: array[MaxFiles, int64]
  var seen: array[MaxFiles, bool]
  for request in 0 ..< int(countValue):
    let id, cost = input[2 + 2 * request], input[3 + 2 * request]
    if id < 0 or id >= MaxFiles or cost < 0 or cost > 20: return -1
    let slot = int(id)
    if seen[slot] and knownCost[slot] != cost: return -1
    seen[slot] = true
    knownCost[slot] = cost

  var ids: array[MaxFiles, int64]
  var credits: array[MaxFiles, int64]
  var residentCount = 0
  var misses, totalCost = 0'i64
  var hitSignature, evictionSignature, residentMask = 0'u64
  for request in 0 ..< int(countValue):
    let id, cost = input[2 + 2 * request], input[3 + 2 * request]
    var position = 0
    while position < residentCount and ids[position] != id: inc position
    if position < residentCount:
      hitSignature = hitSignature or (1'u64 shl request)
      credits[position] = cost
      continue
    inc misses
    totalCost += cost
    var evictedMask = 0'u64
    while residentCount >= int(cacheCapacity):
      var delta = credits[0]
      for i in 1 ..< residentCount:
        if credits[i] < delta: delta = credits[i]
      var kept = 0
      for i in 0 ..< residentCount:
        credits[i] -= delta
        if credits[i] == 0: evictedMask = evictedMask or (1'u64 shl int(ids[i]))
        else:
          ids[kept] = ids[i]
          credits[kept] = credits[i]
          inc kept
      residentCount = kept
    evictionSignature = evictionSignature or (evictedMask shl (8 * request))
    ids[residentCount] = id
    credits[residentCount] = cost
    inc residentCount
  for i in 0 ..< residentCount: residentMask = residentMask or (1'u64 shl int(ids[i]))
  if output == nil or outputCapacity < 40: return -2
  var staged: array[40, uint8]
  storeI64Le(output: cast[ptr UncheckedArray[uint8]](addr staged[0]), offset: 0, value: misses)
  storeI64Le(output: cast[ptr UncheckedArray[uint8]](addr staged[0]), offset: 8, value: totalCost)
  storeI64Le(output: cast[ptr UncheckedArray[uint8]](addr staged[0]), offset: 16, value: int64(hitSignature))
  storeI64Le(output: cast[ptr UncheckedArray[uint8]](addr staged[0]), offset: 24, value: int64(evictionSignature))
  storeI64Le(output: cast[ptr UncheckedArray[uint8]](addr staged[0]), offset: 32, value: int64(residentMask))
  for byte in 0 ..< 40: output[byte] = staged[byte]
  40
