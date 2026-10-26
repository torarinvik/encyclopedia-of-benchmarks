const MaxN = 16
const MaxD = 4
const MaxEdges = 32
const MaxT = 4
const MaxR = 8
const MaxL = 8
const MaxInput = 330

proc put(output: ptr UncheckedArray[uint8], value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8: output[byte] = uint8((bits shr (8 * byte)) and 255)

proc sublinear_bipartiteness_walk_tester*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "sublinear_bipartiteness_walk_tester".} =
  if input.isNil or length < 8 or length > csize_t(MaxInput): return -1
  let n64, d64, m64 = input[0], input[1], input[2]
  if n64 < 1 or n64 > MaxN or d64 < 3 or d64 > MaxD or m64 < 0 or m64 > MaxEdges: return -1
  let n, d, m = int(n64), int(d64), int(m64)
  if m > n * d div 2: return -1
  let suffix = 3 + 2 * m
  if int(length) < suffix + 4: return -1
  let t64, r64, l64 = input[suffix], input[suffix + 1], input[suffix + 2]
  if t64 < 1 or t64 > MaxT or r64 < 1 or r64 > MaxR or l64 < 1 or l64 > MaxL: return -1
  let startsCount, walks, steps = int(t64), int(r64), int(l64)
  if int(length) != suffix + 3 + startsCount + startsCount * walks * steps: return -1
  var adjacent: array[MaxN, array[MaxN, bool]]
  var neighbors: array[MaxN, array[MaxD, int]]
  var degree: array[MaxN, int]
  for edge in 0..<m:
    let a64, b64 = input[3 + 2 * edge], input[4 + 2 * edge]
    if a64 < 0 or b64 < 0 or a64 >= n64 or b64 >= n64 or a64 >= b64: return -1
    let a, b = int(a64), int(b64)
    if adjacent[a][b] or degree[a] >= d or degree[b] >= d: return -1
    adjacent[a][b] = true; adjacent[b][a] = true
    var at = degree[a]
    inc degree[a]
    while at > 0 and neighbors[a][at - 1] > b:
      neighbors[a][at] = neighbors[a][at - 1]
      dec at
    neighbors[a][at] = b
    at = degree[b]
    inc degree[b]
    while at > 0 and neighbors[b][at - 1] > a:
      neighbors[b][at] = neighbors[b][at - 1]
      dec at
    neighbors[b][at] = a
  let startsAt = suffix + 3
  let drawsAt = startsAt + startsCount
  for t in 0..<startsCount:
    if input[startsAt + t] < 0 or input[startsAt + t] >= n64: return -1
  let drawCount = startsCount * walks * steps
  for index in 0..<drawCount:
    if input[drawsAt + index] < 0 or input[drawsAt + index] >= 2 * d64: return -1

  var accepted = true
  var draw = 0
  for t in 0..<startsCount:
    if not accepted: break
    var seen: array[MaxN, array[2, bool]]
    let start = int(input[startsAt + t])
    seen[start][0] = true
    for walk in 0..<walks:
      if not accepted: break
      var vertex = start
      var parity = 0
      for _ in 0..<steps:
        let choice = int(input[drawsAt + draw]); inc draw
        if choice < degree[vertex]:
          vertex = neighbors[vertex][choice]
          parity = 1 - parity
        seen[vertex][parity] = true
        if seen[vertex][1 - parity]: accepted = false; break
  if output.isNil or capacity < 8: return -2
  var staged: array[8, uint8]
  put(addr staged[0], if accepted: 1 else: 0)
  for i in 0..<8: output[i] = staged[i]
  8
