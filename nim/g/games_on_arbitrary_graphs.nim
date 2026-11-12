const
  MaxV = 16
  MaxE = 32
  MaxInput = 66
  MaxOutput = 17

proc games_on_arbitrary_graphs*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "games_on_arbitrary_graphs".} =
  if input.isNil or length < 2 or length > csize_t(MaxInput): return -1
  let nv = input[0]
  let me = input[1]
  if nv < 0 or nv > MaxV or me < 0 or me > MaxE: return -1
  let n = int(nv)
  let m = int(me)
  if length != csize_t(2 + 2 * m): return -1

  var outmask: array[MaxV, uint16]
  var head: array[MaxV, int]
  var edgeSource, edgeNext: array[MaxE, int]
  var remaining, status, queue: array[MaxV, int]
  var staged: array[MaxOutput, uint8]
  for vertex in 0 ..< n: head[vertex] = -1

  var uniqueEdges = 0
  for edgeIndex in 0 ..< m:
    let sv = input[2 + 2 * edgeIndex]
    let tv = input[3 + 2 * edgeIndex]
    if sv < 0 or sv >= nv or tv < 0 or tv >= nv: return -1
    let s = int(sv)
    let t = int(tv)
    let bit = uint16(1) shl t
    if (outmask[s] and bit) == 0:
      outmask[s] = outmask[s] or bit
      edgeSource[uniqueEdges] = s
      edgeNext[uniqueEdges] = head[t]
      head[t] = uniqueEdges
      inc uniqueEdges
      inc remaining[s]

  var first = 0
  var count = 0
  for vertex in 0 ..< n:
    if remaining[vertex] == 0:
      status[vertex] = 2
      queue[count] = vertex
      inc count
  while first < count:
    let resolved = queue[first]
    inc first
    var edge = head[resolved]
    while edge != -1:
      let predecessor = edgeSource[edge]
      if status[predecessor] == 0:
        if status[resolved] == 2:
          status[predecessor] = 1
          queue[count] = predecessor
          inc count
        else:
          dec remaining[predecessor]
          if remaining[predecessor] == 0:
            status[predecessor] = 2
            queue[count] = predecessor
            inc count
      edge = edgeNext[edge]

  staged[0] = uint8(n)
  for vertex in 0 ..< n: staged[vertex + 1] = uint8(status[vertex])
  let needed = n + 1
  if output.isNil or capacity < csize_t(needed): return -2
  for index in 0 ..< needed: output[index] = staged[index]
  int64(needed)
