## Clean-room GBBS Yoshida recursive MIS query; see package LICENSE.txt.
const MaxN = 12
const MaxM = 24
const MaxInput = 52
const MaxCutoff = 128

proc hash64(value: uint64): uint64 =
  var mixed = value *% 3935559000370003845'u64 +% 2691343689449507681'u64
  mixed = mixed xor (mixed shr 21)
  mixed = mixed xor (mixed shl 37)
  mixed = mixed xor (mixed shr 4)
  mixed = mixed *% 4768777513237032717'u64
  mixed = mixed xor (mixed shl 20)
  mixed = mixed xor (mixed shr 41)
  mixed = mixed xor (mixed shl 5)
  return mixed

proc storeI64LE(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  var bits = cast[uint64](value)
  for byte in 0..<8:
    output[offset + byte] = uint8(bits and 255'u64)
    bits = bits shr 8

proc query(vertex: int, degree: array[MaxN, int],
    neighbors: array[MaxN, array[MaxN, int]], priority: array[MaxN, uint64],
    work: var int, cutoff: int): int64 =
  for index in 0..<degree[vertex]:
    if work == cutoff: return -1
    let neighbor = neighbors[vertex][index]
    inc work
    if priority[vertex] < priority[neighbor] or
        (priority[vertex] == priority[neighbor] and vertex <= neighbor): break
    let status = query(neighbor, degree, neighbors, priority, work, cutoff)
    if status == 1: return 0
    if status == -1: return -1
  return 1

proc gbbs_yoshida_query_mis*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "gbbs_yoshida_query_mis".} =
  if input.isNil or length < csize_t(4) or length > csize_t(MaxInput): return -1
  let n64 = input[0]
  let m64 = input[1]
  let root64 = input[2]
  let cutoff64 = input[3]
  if n64 < 1 or n64 > MaxN or m64 < 0 or m64 > MaxM or root64 < 0 or root64 >= n64 or
      cutoff64 < 0 or cutoff64 > MaxCutoff or int64(length) != 4 + 2 * m64: return -1
  let n = int(n64)
  let m = int(m64)
  var adjacent: array[MaxN, array[MaxN, bool]]
  var degree: array[MaxN, int]
  for edge in 0..<m:
    let u64 = input[4 + 2 * edge]
    let v64 = input[5 + 2 * edge]
    if u64 < 0 or v64 <= u64 or v64 >= n64: return -1
    let u = int(u64)
    let v = int(v64)
    if adjacent[u][v]: return -1
    adjacent[u][v] = true
    adjacent[v][u] = true
    inc degree[u]
    inc degree[v]
  if output.isNil or capacity < csize_t(16): return -2
  var priority: array[MaxN, uint64]
  var neighbors: array[MaxN, array[MaxN, int]]
  for vertex in 0..<n: priority[vertex] = hash64(uint64(vertex))
  for vertex in 0..<n:
    var inserted = 0
    for other in 0..<n:
      if adjacent[vertex][other]:
        var position = inserted
        while position > 0:
          let previous = neighbors[vertex][position - 1]
          if priority[previous] < priority[other] or
              (priority[previous] == priority[other] and previous < other): break
          neighbors[vertex][position] = previous
          dec position
        neighbors[vertex][position] = other
        inc inserted
  var work = 0
  let status = query(int(root64), degree, neighbors, priority, work, int(cutoff64))
  storeI64LE(output, 0, status)
  storeI64LE(output, 8, int64(work))
  return 16
