const MaxRequests = 7
const MaxFiles = 8
const MaxInput = 23

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc landlord_file_caching*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "landlord_file_caching".} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxInput): return -1
  let capacityValue, countValue = input[0], input[1]
  if capacityValue < 1 or capacityValue > 8 or countValue < 0 or countValue > MaxRequests or
      int(length) != 2 + 3 * int(countValue): return -1
  var knownSize, knownCost: array[MaxFiles, int64]
  var seen: array[MaxFiles, bool]
  let count = int(countValue)
  for request in 0 ..< count:
    let idValue, size, cost = input[2 + 3 * request], input[3 + 3 * request], input[4 + 3 * request]
    if idValue < 0 or idValue >= MaxFiles or size < 1 or size > 4 or size > capacityValue or cost < 0 or cost > 20: return -1
    let id = int(idValue)
    if seen[id] and (knownSize[id] != size or knownCost[id] != cost): return -1
    seen[id] = true
    knownSize[id] = size
    knownCost[id] = cost

  var ids, sizes, credits: array[MaxFiles, int64]
  var residentCount = 0
  var misses, totalCost = 0'i64
  var hitSignature, evictionSignature, residentMask = 0'u64
  for request in 0 ..< count:
    let id = input[2 + 3 * request]
    let size = input[3 + 3 * request]
    let cost = input[4 + 3 * request]
    var position = 0
    while position < residentCount and ids[position] != id: inc position
    if position < residentCount:
      hitSignature = hitSignature or (1'u64 shl request)
      continue
    inc misses
    totalCost += cost
    var evictedMask = 0'u64
    var used = 0'i64
    for i in 0 ..< residentCount: used += sizes[i]
    while used + size > capacityValue:
      var delta = credits[0] div sizes[0]
      for i in 1 ..< residentCount:
        let ratio = credits[i] div sizes[i]
        if ratio < delta: delta = ratio
      var kept = 0
      used = 0
      for i in 0 ..< residentCount:
        credits[i] -= delta * sizes[i]
        if credits[i] == 0: evictedMask = evictedMask or (1'u64 shl int(ids[i]))
        else:
          ids[kept] = ids[i]
          sizes[kept] = sizes[i]
          credits[kept] = credits[i]
          used += sizes[kept]
          inc kept
      residentCount = kept
    evictionSignature = evictionSignature or (evictedMask shl (8 * request))
    ids[residentCount] = id
    sizes[residentCount] = size
    credits[residentCount] = cost * 12
    inc residentCount
  for i in 0 ..< residentCount: residentMask = residentMask or (1'u64 shl int(ids[i]))
  if output.isNil or capacity < csize_t(40): return -2
  var staged: array[40, uint8]
  storeI64Le(addr staged[0], 0, misses)
  storeI64Le(addr staged[0], 8, totalCost)
  storeI64Le(addr staged[0], 16, int64(hitSignature))
  storeI64Le(addr staged[0], 24, int64(evictionSignature))
  storeI64Le(addr staged[0], 32, int64(residentMask))
  for byte in 0 ..< 40: output[byte] = staged[byte]
  40
