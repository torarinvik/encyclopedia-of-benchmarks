## Return the edge that first closes the cycle under input-order union-find.
const MaxVertices = 1000

proc findRoot(parents: ptr UncheckedArray[int32], nodeValue: int32): int32 =
  var node = nodeValue
  var root = node
  while parents[int(root)] != root: root = parents[int(root)]
  while parents[int(node)] != node:
    let next = parents[int(node)]
    parents[int(node)] = root
    node = next
  root

proc redundant_connection*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "redundant_connection".} =
  if length < 6 or length > csize_t(MaxVertices * 2) or length mod 2 != 0 or values.isNil: return -1
  let edgeCount = int(length div 2)
  for index in 0 ..< int(length):
    if values[index] < 1 or values[index] > int64(edgeCount): return -1
  for edge in 0 ..< edgeCount:
    if values[2 * edge] == values[2 * edge + 1]: return -1

  var parents: array[MaxVertices + 1, int32]
  for node in 0 .. edgeCount: parents[node] = int32(node)
  let parentPointer = cast[ptr UncheckedArray[int32]](addr parents[0])
  var redundantLeft = 0'i64
  var redundantRight = 0'i64
  var redundantCount = 0
  for edge in 0 ..< edgeCount:
    let left = int32(values[2 * edge])
    let right = int32(values[2 * edge + 1])
    let leftRoot = findRoot(parentPointer, left)
    let rightRoot = findRoot(parentPointer, right)
    if leftRoot == rightRoot:
      redundantLeft = int64(left)
      redundantRight = int64(right)
      inc redundantCount
    else:
      parents[int(leftRoot)] = rightRoot
  if redundantCount != 1: return -1
  if outputCapacity < 8 or output.isNil: return -2
  for endpoint, value in [redundantLeft, redundantRight]:
    let bits = uint32(value)
    for byte in 0 ..< 4:
      output[endpoint * 4 + byte] = uint8((bits shr (byte * 8)) and 255)
  2
