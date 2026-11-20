const
  MaxN = 12
  MaxM = 66
  MaxParseable = 135
  MaxOutput = 47

proc ctComponents(mask: uint16, adjacency: array[MaxN, uint16], complement: bool,
                  parts: var array[MaxN, uint16]): int =
  var remaining = mask
  for root in 0 ..< MaxN:
    let rootBit = 1'u16 shl root
    if (remaining and rootBit) == 0: continue
    var reached = rootBit
    var queue: array[MaxN, int]
    var head = 0
    var tail = 1
    queue[0] = root
    while head < tail:
      let vertex = queue[head]
      inc head
      var neighbors = adjacency[vertex] and mask
      if complement:
        neighbors = mask and not adjacency[vertex] and not (1'u16 shl vertex)
      var fresh = neighbors and not reached
      for next in 0 ..< MaxN:
        let bit = 1'u16 shl next
        if (fresh and bit) != 0:
          fresh = fresh and not bit
          reached = reached or bit
          queue[tail] = next
          inc tail
    parts[result] = reached
    inc result
    remaining = remaining and not reached

proc ctEmit(mask: uint16, adjacency: array[MaxN, uint16],
            output: var array[MaxOutput, uint8], position: var int): bool =
  if (mask and (mask - 1)) == 0:
    output[position] = 0
    var vertex = 0
    while (mask and (1'u16 shl vertex)) == 0: inc vertex
    output[position + 1] = uint8(vertex)
    position += 2
    return true
  var parts: array[MaxN, uint16]
  var count = ctComponents(mask, adjacency, false, parts)
  var kind = 1'u8
  if count == 1:
    count = ctComponents(mask, adjacency, true, parts)
    kind = 2
    if count <= 1: return false
  output[position] = kind
  output[position + 1] = uint8(count)
  position += 2
  for i in 0 ..< count:
    if not ctEmit(parts[i], adjacency, output, position): return false
  true

proc cograph_cotree_decomposition*(input: ptr UncheckedArray[int64], length: csize_t,
                                   output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "cograph_cotree_decomposition".} =
  if input == nil or length < 2 or length > csize_t(MaxParseable): return -1
  let n64 = input[0]
  let m64 = input[1]
  if n64 < 1 or n64 > MaxN or m64 < 0 or m64 > MaxM or m64 > n64 * (n64 - 1) div 2 or
      length != csize_t(2 + 2 * m64): return -1
  let n = int(n64)
  let m = int(m64)
  var adjacency: array[MaxN, uint16]
  for edge in 0 ..< m:
    let u64 = input[2 + 2 * edge]
    let v64 = input[3 + 2 * edge]
    if u64 < 0 or u64 >= n64 or v64 < 0 or v64 >= n64 or u64 == v64: return -1
    let u = int(u64)
    let v = int(v64)
    let ub = 1'u16 shl u
    let vb = 1'u16 shl v
    if (adjacency[u] and vb) != 0: return -1
    adjacency[u] = adjacency[u] or vb
    adjacency[v] = adjacency[v] or ub
  var staged: array[MaxOutput, uint8]
  var outputLength = 1
  if ctEmit((1'u16 shl n) - 1, adjacency, staged, outputLength): staged[0] = 1
  else:
    staged[0] = 0
    outputLength = 1
  if output == nil or capacity < csize_t(outputLength): return -2
  for i in 0 ..< outputLength: output[i] = staged[i]
  int64(outputLength)
