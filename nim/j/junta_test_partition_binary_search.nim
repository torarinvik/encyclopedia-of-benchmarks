const MaxN = 8
const Rounds = 24
const MaxGroups = 8
const MaxOutputWords = 7

proc truthAt(table: ptr UncheckedArray[uint64], point: uint32): int64 =
  let word = int(point div 64)
  let bit = int(point mod 64)
  int64((table[word] shr bit) and 1'u64)

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc junta_test_partition_binary_search*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "junta_test_partition_binary_search".} =
  if input.isNil or length < 3 or length > 40: return -1
  let n64 = input[0]
  let group64 = input[1]
  let words64 = input[2]
  if n64 < 1 or n64 > MaxN or group64 < 1 or group64 > n64: return -1
  let n = int(n64)
  let groupCount = int(group64)
  let domain = 1 shl n
  let truthWords = (domain + 63) div 64
  if words64 != int64(truthWords): return -1
  let tableAt = 3
  let labelsAt = tableAt + truthWords
  let tapeAt = labelsAt + n
  if int(length) != tapeAt + Rounds: return -1

  var table: array[4, uint64]
  for word in 0 ..< truthWords: table[word] = cast[uint64](input[tableAt + word])
  let tailBits = domain mod 64
  if tailBits != 0 and (table[truthWords - 1] shr tailBits) != 0: return -1

  var groupMasks: array[MaxGroups, uint32]
  var groupsSeen = 0'u32
  for coordinate in 0 ..< n:
    let group = input[labelsAt + coordinate]
    if group < 0 or group >= group64: return -1
    groupMasks[int(group)] = groupMasks[int(group)] or (1'u32 shl coordinate)
    groupsSeen = groupsSeen or (1'u32 shl int(group))
  if groupsSeen != ((1'u32 shl groupCount) - 1'u32): return -1
  let pairLimit = 1'u64 shl (2 * n)
  for round in 0 ..< Rounds:
    let pair = input[tapeAt + round]
    if pair < 0 or cast[uint64](pair) >= pairLimit: return -1

  var result: array[MaxOutputWords, int64]
  var eventRounds: array[2, int64]
  var eventGroups: array[2, int64]
  var found = 0
  var queryCount = 0
  let allCoordinates = (1'u32 shl n) - 1'u32
  var active = allCoordinates
  for round in 0 ..< Rounds:
    let packed = cast[uint64](input[tapeAt + round])
    let x = uint32(packed and uint64(allCoordinates))
    let y = uint32((packed shr n) and uint64(allCoordinates))
    let hybrid = (x and not active) or (y and active)
    var leftValue = truthAt(addr table[0], x)
    let rightValue = truthAt(addr table[0], hybrid)
    queryCount += 2
    if leftValue == rightValue: continue

    var candidates: array[MaxGroups, uint8]
    var candidateCount = 0
    for group in 0 ..< groupCount:
      if (groupMasks[group] and active) != 0:
        candidates[candidateCount] = uint8(group)
        inc candidateCount
    var leftEndpoint = x
    var rightEndpoint = hybrid
    while candidateCount > 1:
      let cut = candidateCount div 2
      var lowMask = 0'u32
      for i in 0 ..< cut: lowMask = lowMask or groupMasks[int(candidates[i])]
      let probe = (leftEndpoint and not lowMask) or (rightEndpoint and lowMask)
      let probeValue = truthAt(addr table[0], probe)
      inc queryCount
      if probeValue != leftValue:
        rightEndpoint = probe
        candidateCount = cut
      else:
        leftEndpoint = probe
        leftValue = probeValue
        for i in cut ..< candidateCount: candidates[i - cut] = candidates[i]
        candidateCount -= cut

    let selected = int(candidates[0])
    active = active and not groupMasks[selected]
    eventRounds[found] = int64(round)
    eventGroups[found] = int64(selected)
    inc found
    if found > 1: break

  result[0] = if found > 1: 1 else: 0
  result[1] = int64(found)
  result[2] = int64(queryCount)
  for i in 0 ..< found:
    result[3 + 2 * i] = eventRounds[i]
    result[4 + 2 * i] = eventGroups[i]
  let resultWords = 3 + 2 * found
  let resultBytes = resultWords * 8
  if output.isNil or capacity < csize_t(resultBytes): return -2
  for i in 0 ..< resultWords: storeI64Le(output, i * 8, result[i])
  int64(resultBytes)
