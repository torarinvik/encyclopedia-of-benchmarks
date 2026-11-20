const MaxN = 8
const MaxM = 28
const MaxInput = 59

type
  I64Input = ptr UncheckedArray[int64]
  ByteOutput = ptr UncheckedArray[uint8]
  Graph = array[MaxN, uint16]

proc putWord(output: ByteOutput, offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc fmt(vertices: uint16, graph: Graph): uint64 =
  var complete = true
  for u in 0 ..< MaxN:
    if ((vertices shr u) and 1'u16) != 0:
      let others = vertices and not (1'u16 shl u)
      if (graph[u] and others) != others: complete = false
  if complete: return 0
  var pivot = 0
  while ((vertices shr pivot) and 1'u16) == 0 or
      (graph[pivot] and (vertices and not (1'u16 shl pivot))) == (vertices and not (1'u16 shl pivot)):
    inc pivot
  let a = (1'u16 shl pivot) or (graph[pivot] and vertices)
  var unseen = vertices and not a
  var components: array[MaxN, uint16]
  var closures: array[MaxN, uint16]
  var count = 0
  while unseen != 0:
    var seed = 0
    while ((unseen shr seed) and 1'u16) == 0: inc seed
    var comp = 1'u16 shl seed
    unseen = unseen and not comp
    var frontier = comp
    while frontier != 0:
      var u = 0
      while ((frontier shr u) and 1'u16) == 0: inc u
      frontier = frontier and not (1'u16 shl u)
      let added = graph[u] and unseen
      comp = comp or added
      frontier = frontier or added
      unseen = unseen and not added
    components[count] = comp
    inc count
  var saturated = graph
  var fillMask = 0'u64
  for ci in 0 ..< count:
    let comp = components[ci]
    var boundary = 0'u16
    for u in 0 ..< MaxN:
      if ((comp shr u) and 1'u16) != 0: boundary = boundary or (graph[u] and vertices and not comp)
    closures[ci] = comp or boundary
    for u in 0 ..< MaxN:
      if ((boundary shr u) and 1'u16) == 0: continue
      for v in u + 1 ..< MaxN:
        if ((boundary shr v) and 1'u16) != 0 and ((saturated[u] shr v) and 1'u16) == 0:
          saturated[u] = saturated[u] or (1'u16 shl v)
          saturated[v] = saturated[v] or (1'u16 shl u)
          fillMask = fillMask or (1'u64 shl (u * MaxN + v))
  fillMask = fillMask or fmt(a, saturated)
  for ci in 0 ..< count: fillMask = fillMask or fmt(closures[ci], saturated)
  fillMask

proc fast_minimal_triangulation*(input: I64Input, length: csize_t, output: ByteOutput,
    capacity: csize_t): int64 {.cdecl, exportc: "fast_minimal_triangulation".} =
  if input == nil or length < csize_t(2) or length > csize_t(MaxInput): return -1
  let n64 = input[0]; let m64 = input[1]
  if n64 < 1 or n64 > MaxN or m64 < 0 or m64 > MaxM or int64(length) != 2 + 2 * m64: return -1
  let n = int(n64); let m = int(m64)
  var graph: Graph
  var original = 0'u64
  var previousU = -1'i64; var previousV = -1'i64
  for i in 0 ..< m:
    let u64 = input[2 + 2 * i]; let v64 = input[3 + 2 * i]
    if u64 < 0 or v64 <= u64 or v64 >= n64 or u64 < previousU or (u64 == previousU and v64 <= previousV): return -1
    let u = int(u64); let v = int(v64)
    previousU = u64; previousV = v64
    graph[u] = graph[u] or (1'u16 shl v); graph[v] = graph[v] or (1'u16 shl u)
    original = original or (1'u64 shl (u * MaxN + v))
  let fill = fmt((1'u16 shl n) - 1, graph) and not original
  var count = 0
  for u in 0 ..< n:
    for v in u + 1 ..< n:
      if ((fill shr (u * MaxN + v)) and 1'u64) != 0: inc count
  let bytes = 8 * (1 + 2 * count)
  if output == nil or capacity < csize_t(bytes): return -2
  putWord(output, 0, int64(count))
  var index = 1
  for u in 0 ..< n:
    for v in u + 1 ..< n:
      if ((fill shr (u * MaxN + v)) and 1'u64) != 0:
        putWord(output, 8 * index, int64(u)); inc index
        putWord(output, 8 * index, int64(v)); inc index
  int64(bytes)
