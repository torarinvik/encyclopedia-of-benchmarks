# Clean-room bounded GBBS widest-path profile; see package LICENSE.txt.
const MaxN = 16
const MaxM = 64
const MaxInput = 195
const SourceInfinity = 2_147_483_647'i64

proc storeI64LE(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255)

proc gbbs_ss_widest_path*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "gbbs_ss_widest_path".} =
  if input.isNil or length < csize_t(3) or length > csize_t(MaxInput): return -1
  let n64 = input[0]
  let m64 = input[1]
  let source64 = input[2]
  if n64 < 1 or n64 > int64(MaxN) or m64 < 0 or m64 > int64(MaxM) or
      source64 < 0 or source64 >= n64 or int64(length) != 3 + 3 * m64: return -1
  let n = int(n64)
  let m = int(m64)
  let source = int(source64)
  var edgeFrom: array[MaxM, int]
  var edgeTo: array[MaxM, int]
  var edgeCapacity: array[MaxM, int64]
  for edge in 0..<m:
    let from = input[3 + 3 * edge]
    let to = input[4 + 3 * edge]
    let edgeWidth = input[5 + 3 * edge]
    if from < 0 or from >= n64 or to < 0 or to >= n64 or edgeWidth < 1 or edgeWidth > 32: return -1
    edgeFrom[edge] = int(from)
    edgeTo[edge] = int(to)
    edgeCapacity[edge] = edgeWidth
  let outputBytes = 8 * n
  if output.isNil or capacity < csize_t(outputBytes): return -2

  var width: array[MaxN, int64]
  var settled: array[MaxN, bool]
  width[source] = SourceInfinity
  for _step in 0..<n:
    var u = -1
    for vertex in 0..<n:
      if not settled[vertex] and (u < 0 or width[vertex] > width[u]): u = vertex
    if u < 0 or width[u] == 0: break
    settled[u] = true
    for edge in 0..<m:
      if edgeFrom[edge] != u: continue
      let v = edgeTo[edge]
      if settled[v]: continue
      let candidate = min(width[u], edgeCapacity[edge])
      if candidate > width[v]: width[v] = candidate
  for vertex in 0..<n: storeI64LE(output, 8 * vertex, width[vertex])
  int64(outputBytes)
