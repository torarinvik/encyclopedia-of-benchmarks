const MaxVertices = 16
const MaxEdges = 64
const MaxInputLength = 3 + 3 * MaxEdges

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255)

proc d_esopo_pape*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "d_esopo_pape".} =
  if values == nil or length < 3 or length > csize_t(MaxInputLength): return -1
  let rawN = values[0]
  let rawM = values[1]
  let rawSource = values[2]
  if rawN < 1 or rawN > int64(MaxVertices) or rawM < 0 or rawM > int64(MaxEdges) or
      rawSource < 0 or rawSource >= rawN or length != csize_t(3 + 3 * rawM):
    return -1

  let n = int(rawN)
  let m = int(rawM)
  var head: array[MaxVertices, int]
  var to: array[MaxEdges, int]
  var next: array[MaxEdges, int]
  var weight: array[MaxEdges, int64]
  for vertex in 0 ..< n: head[vertex] = -1
  for edge in 0 ..< m:
    let u = values[3 + 3 * edge]
    let v = values[4 + 3 * edge]
    let w = values[5 + 3 * edge]
    if u < 0 or u >= rawN or v < 0 or v >= rawN or w < 0 or w > 1000: return -1
    to[edge] = int(v)
    weight[edge] = w
    next[edge] = head[int(u)]
    head[int(u)] = edge

  var distance: array[MaxVertices, int64]
  var reachable: array[MaxVertices, bool]
  var queued: array[MaxVertices, bool]
  var removedBefore: array[MaxVertices, bool]
  var deque: array[MaxVertices, int]
  var front = 0
  var size = 1
  let source = int(rawSource)
  deque[0] = source
  distance[source] = 0
  reachable[source] = true
  queued[source] = true
  while size > 0:
    let vertex = deque[front]
    front = (front + 1) mod n
    dec size
    queued[vertex] = false
    removedBefore[vertex] = true
    var edge = head[vertex]
    while edge >= 0:
      let neighbor = to[edge]
      let candidate = distance[vertex] + weight[edge]
      if not reachable[neighbor] or candidate < distance[neighbor]:
        distance[neighbor] = candidate
        reachable[neighbor] = true
        if not queued[neighbor]:
          if removedBefore[neighbor]:
            front = (front + n - 1) mod n
            deque[front] = neighbor
          else:
            deque[(front + size) mod n] = neighbor
          inc size
          queued[neighbor] = true
      edge = next[edge]

  let byteCount = 8 * n
  if output == nil or outputCapacity < csize_t(byteCount): return -2
  for vertex in 0 ..< n:
    storeI64Le(output, 8 * vertex, if reachable[vertex]: distance[vertex] else: -1)
  int64(byteCount)
