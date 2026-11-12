const MaxVertices = 8
const MaxEdges = 16
const MaxInputLength = 2 + 2 * MaxEdges

type
  Adjacency = array[MaxVertices, uint64]
  Polynomial = array[MaxVertices + 1, int64]

proc chromaticPoly(adjacency: Adjacency, n: int): Polynomial =
  var edgeU = n
  var edgeV = n
  for u in 0 ..< n:
    if edgeU == n:
      for v in u + 1 ..< n:
        if (adjacency[u] and (1'u64 shl v)) != 0:
          edgeU = u
          edgeV = v
          break
  if edgeU == n:
    result[n] = 1
    return

  var deleted = adjacency
  deleted[edgeU] = deleted[edgeU] and not (1'u64 shl edgeV)
  deleted[edgeV] = deleted[edgeV] and not (1'u64 shl edgeU)
  let withoutEdge = chromaticPoly(deleted, n)

  var contracted: Adjacency
  for left in 0 ..< n:
    for right in left + 1 ..< n:
      if (adjacency[left] and (1'u64 shl right)) != 0 and not (left == edgeU and right == edgeV):
        var newLeft = left
        var newRight = right
        if newLeft == edgeV: newLeft = edgeU
        if newRight == edgeV: newRight = edgeU
        if newLeft > edgeV: dec newLeft
        if newRight > edgeV: dec newRight
        if newLeft != newRight:
          contracted[newLeft] = contracted[newLeft] or (1'u64 shl newRight)
          contracted[newRight] = contracted[newRight] or (1'u64 shl newLeft)
  let withEdgeContracted = chromaticPoly(contracted, n - 1)
  for degree in 0 .. n:
    result[degree] = withoutEdge[degree] - withEdgeContracted[degree]

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc chromatic_polynomial*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "chromatic_polynomial".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputLength): return -1
  let nValue = input[0]
  let mValue = input[1]
  if nValue < 0 or nValue > MaxVertices or mValue < 0 or mValue > MaxEdges: return -1
  let n = int(nValue)
  let m = int(mValue)
  if length != csize_t(2 + 2 * m): return -1

  var adjacency: Adjacency
  for edge in 0 ..< m:
    let uValue = input[2 + 2 * edge]
    let vValue = input[3 + 2 * edge]
    if uValue < 0 or uValue >= nValue or vValue < 0 or vValue >= nValue or uValue == vValue: return -1
    let u = int(uValue)
    let v = int(vValue)
    if (adjacency[u] and (1'u64 shl v)) != 0: return -1
    adjacency[u] = adjacency[u] or (1'u64 shl v)
    adjacency[v] = adjacency[v] or (1'u64 shl u)

  let outputBytes = 8 * (n + 1)
  if output.isNil or capacity < csize_t(outputBytes): return -2
  let coefficients = chromaticPoly(adjacency, n)
  for degree in 0 .. n:
    storeI64Le(output, 8 * degree, coefficients[degree])
  int64(outputBytes)
