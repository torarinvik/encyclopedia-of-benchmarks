## Clean-room exact dyadic CoSimRank profile; see package LICENSE.txt.
const MaxN = 8
const MaxM = 24
const MaxInput = 53

proc storeScaledBinary64(output: ptr UncheckedArray[uint8], numerator: uint32) =
  var bits = 0'u64
  if numerator != 0:
    var high = 0
    var probe = numerator
    while probe > 1:
      probe = probe shr 1
      inc high
    let exponent = uint64(1003 + high)
    let significand = uint64(numerator) shl (52 - high)
    bits = (exponent shl 52) or (significand and ((1'u64 shl 52) - 1))
  for byte in 0..<8:
    output[byte] = uint8(bits and 255)
    bits = bits shr 8

proc gbbs_cosimrank_pair_similarity*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "gbbs_cosimrank_pair_similarity".} =
  if input.isNil or length < csize_t(5) or length > csize_t(MaxInput): return -1
  let n64 = input[0]
  let m64 = input[1]
  let sourceU64 = input[2]
  let sourceV64 = input[3]
  let iterations64 = input[4]
  if n64 < 1 or n64 > MaxN or m64 < 0 or m64 > MaxM or sourceU64 < 0 or sourceU64 >= n64 or
      sourceV64 < 0 or sourceV64 >= n64 or iterations64 < 1 or iterations64 > 4 or
      int64(length) != 5 + 2 * m64: return -1
  let n = int(n64)
  let m = int(m64)
  var edgeFrom: array[MaxM, int]
  var edgeTo: array[MaxM, int]
  var degree: array[MaxN, int]
  var seen: array[MaxN, array[MaxN, bool]]
  for edge in 0..<m:
    let from64 = input[5 + 2 * edge]
    let to64 = input[6 + 2 * edge]
    if from64 < 0 or from64 >= n64 or to64 < 0 or to64 >= n64 or from64 == to64: return -1
    let from = int(from64)
    let to = int(to64)
    if seen[from][to]: return -1
    seen[from][to] = true
    edgeFrom[edge] = from
    edgeTo[edge] = to
    inc degree[from]
  for vertex in 0..<n:
    if degree[vertex] != 0 and degree[vertex] != 1 and degree[vertex] != 2 and degree[vertex] != 4: return -1
  if output.isNil or capacity < csize_t(8): return -2
  var currentU, currentV, nextU, nextV: array[MaxN, uint32]
  currentU[int(sourceU64)] = 256
  currentV[int(sourceV64)] = 256
  var numerator = if sourceU64 == sourceV64: (1'u32 shl 20) else: 0'u32
  for step in 0..<int(iterations64):
    for edge in 0..<m:
      let from = edgeFrom[edge]
      let to = edgeTo[edge]
      nextU[to] += currentU[from] div uint32(degree[from])
      nextV[to] += currentV[from] div uint32(degree[from])
    var dot = 0'u32
    for vertex in 0..<n: dot += nextU[vertex] * nextV[vertex]
    numerator += dot shl (3 - step)
    for vertex in 0..<n:
      currentU[vertex] = nextU[vertex]
      currentV[vertex] = nextV[vertex]
      nextU[vertex] = 0
      nextV[vertex] = 0
  storeScaledBinary64(output, numerator)
  8
