const MaxN = 12
const MaxWeight = 32
const MaxLevels = 6
const MaxInput = 25
const MaxOutput = 104

proc put(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc universal_sequencing_doubling*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "universal_sequencing_doubling".} =
  if input.isNil or length < 3 or length > csize_t(MaxInput): return -1
  let n64 = input[0]
  if n64 < 1 or n64 > MaxN or int(length) != 1 + 2 * int(n64): return -1
  let n = int(n64)
  var processing: array[MaxN, int64]
  var weight: array[MaxN, int]
  var totalWeight = 0
  for job in 0..<n:
    let p = input[1 + 2 * job]
    let w = input[2 + 2 * job]
    if p < 1 or p > 255 or w < 1 or w > MaxWeight: return -1
    processing[job] = p
    weight[job] = int(w)
    totalWeight += int(w)
  if totalWeight > MaxWeight or (totalWeight and (totalWeight - 1)) != 0: return -1

  var levelSets: array[MaxLevels, uint16]
  var levels = 0
  var bound = 1
  while bound <= totalWeight:
    var best: array[MaxWeight + 1, int64]
    var masks: array[MaxWeight + 1, uint16]
    var reachable: array[MaxWeight + 1, bool]
    reachable[0] = true
    for job in 0..<n:
      var used = bound
      while used >= weight[job]:
        if reachable[used - weight[job]]:
          let candidate = best[used - weight[job]] + processing[job]
          let candidateMask = masks[used - weight[job]] or (1'u16 shl job)
          if not reachable[used] or candidate > best[used] or
              (candidate == best[used] and candidateMask < masks[used]):
            reachable[used] = true
            best[used] = candidate
            masks[used] = candidateMask
        dec used
    var maximum: int64 = -1
    var selected: uint16 = 0
    for used in 0..bound:
      if reachable[used] and (best[used] > maximum or
          (best[used] == maximum and masks[used] < selected)):
        maximum = best[used]
        selected = masks[used]
    levelSets[levels] = selected
    inc levels
    bound *= 2

  var rank: array[MaxN, int]
  for job in 0..<n:
    rank[job] = -1
    for level in 0..<levels:
      if (levelSets[level] and (1'u16 shl job)) != 0:
        rank[job] = level
        break
    if rank[job] < 0: return -1
  var words: array[MaxN + 1, int64]
  words[0] = int64(n)
  var count = 1
  for level in countdown(levels - 1, 0):
    for job in 0..<n:
      if rank[job] == level:
        words[count] = int64(job)
        inc count
  let bytes = 8 * count
  if output.isNil or capacity < csize_t(bytes): return -2
  var staged: array[MaxOutput, uint8]
  for i in 0..<count: put(addr staged[0], 8 * i, words[i])
  for i in 0..<bytes: output[i] = staged[i]
  int64(bytes)
