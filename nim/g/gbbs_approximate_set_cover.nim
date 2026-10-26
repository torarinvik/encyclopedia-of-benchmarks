# Clean-room bounded GBBS approximate set-cover profile; see package MIT notice.
proc storeI64LE(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc popCount16(value: uint16): int =
  var bits = value
  while bits != 0:
    bits = bits and (bits - 1)
    inc result

proc gbbs_approximate_set_cover*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "gbbs_approximate_set_cover".} =
  if input.isNil or length < 2 or length > 10: return -1
  let ns64 = input[0]
  if ns64 < 1 or ns64 > 8: return -1
  let ns = int(ns64)
  let ne = ns
  if int(length) != 1 + ns: return -1
  let valid = uint16((1 shl ne) - 1)
  var sets: array[8, uint16]
  for s in 0..<ns:
    if input[1+s] < 0 or (uint64(input[1+s]) and not uint64(valid)) != 0: return -1
    sets[s] = uint16(input[1+s])
    if (sets[s] and uint16(1 shl s)) != 0: return -1
  for u in 0..<ns:
    for v in 0..<ns:
      if ((sets[u] shr v) and 1) != ((sets[v] shr u) and 1): return -1
  if output.isNil or capacity < 16: return -2
  var uncovered = valid
  var selected = uint16(0)
  var bucket: array[8, int]
  for s in 0..<ns: bucket[s] = popCount16(sets[s])
  var round = 0
  while uncovered != 0:
    var degree: array[8, int]
    var top = 0
    for s in 0..<ns:
      if bucket[s] > top: top = bucket[s]
    if top == 0: break
    var eligible: array[8, bool]
    var eligibleCount = 0
    for s in 0..<ns:
      if bucket[s] == top:
        degree[s] = popCount16(sets[s] and uncovered)
        bucket[s] = degree[s]
        eligible[s] = degree[s] >= top
        if eligible[s]: inc eligibleCount
    var priority: array[8, int]
    var priorityCount = 0
    for r in 0..<ns:
      let s = (round + r) mod ns
      if eligible[s]:
        priority[priorityCount] = s
        inc priorityCount
    var wins: array[8, int]
    for e in 0..<ne:
      let bit = uint16(1 shl e)
      if (uncovered and bit) == 0: continue
      for r in 0..<priorityCount:
        let s = priority[r]
        if (sets[s] and bit) != 0:
          inc wins[s]
          break
    var roundCover = uint16(0)
    for s in 0..<ns:
      if eligible[s] and wins[s] >= top: roundCover = roundCover or uint16(1 shl s)
    if roundCover == 0 and eligibleCount != 0: return -1
    selected = selected or roundCover
    var covered = uint16(0)
    for s in 0..<ns:
      if (roundCover and uint16(1 shl s)) != 0: covered = covered or sets[s]
    uncovered = uncovered and not covered
    for s in 0..<ns:
      if (roundCover and uint16(1 shl s)) != 0: bucket[s] = 0
    inc round
  storeI64LE(output, 0, int64(selected))
  storeI64LE(output, 8, int64(uncovered))
  return 16
