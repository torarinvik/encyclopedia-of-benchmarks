const MaxN = 8
const MaxInput = MaxN + 1
const MaxCliques = 256
const MaxOutputBytes = 8 + MaxCliques

proc visit(n: int, adjacency: array[MaxN, uint16], clique: uint16,
    masks: var array[MaxCliques, uint8], count: var int) =
  masks[count] = uint8(clique)
  inc count
  var minimum = n
  for vertex in 0 ..< n:
    if (clique and (uint16(1) shl vertex)) != 0:
      minimum = vertex
      break
  for vertex in 0 ..< minimum:
    let bit = uint16(1) shl vertex
    if (clique and bit) == 0 and (adjacency[vertex] and clique) == clique:
      visit(n, adjacency, clique or bit, masks, count)

proc storeI64Le(output: ptr UncheckedArray[uint8], value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[byte] = uint8((bits shr (8 * byte)) and 255)

proc clique_reverse_search_enumeration*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "clique_reverse_search_enumeration".} =
  if input == nil or length < 2 or length > csize_t(MaxInput): return -1
  let nValue = input[0]
  if nValue < 1 or nValue > MaxN or length != csize_t(nValue + 1): return -1
  let n = int(nValue)
  var adjacency: array[MaxN, uint16]
  for vertex in 0 ..< n:
    let raw = input[vertex + 1]
    if raw < 0 or raw >= (1'i64 shl n) or (raw and (1'i64 shl vertex)) != 0: return -1
    adjacency[vertex] = uint16(raw)
  for left in 0 ..< n:
    for right in left + 1 ..< n:
      let edgeLeft = (adjacency[left] and (uint16(1) shl right)) != 0
      let edgeRight = (adjacency[right] and (uint16(1) shl left)) != 0
      if edgeLeft != edgeRight: return -1

  var masks: array[MaxCliques, uint8]
  var count = 0
  visit(n, adjacency, 0, masks, count)
  let required = 8 + count
  if output == nil or capacity < csize_t(required): return -2
  var staged: array[MaxOutputBytes, uint8]
  storeI64Le(output: cast[ptr UncheckedArray[uint8]](addr staged[0]), value: int64(count))
  for index in 0 ..< count: staged[8 + index] = masks[index]
  for byte in 0 ..< required: output[byte] = staged[byte]
  int64(required)
