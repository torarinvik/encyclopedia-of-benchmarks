const MaxLeaves = 8
const MaxEdges = 13
const MaxInput = 27

proc storeI64Le(output: ptr UncheckedArray[uint8], value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[byte] = uint8((bits shr (8 * byte)) and 255)

proc bitCount(value: uint64, n: int): int =
  for bit in 0 ..< n: result += int((value shr bit) and 1)

proc validTree(input: ptr UncheckedArray[int64], offset, n, edges: int): bool =
  var masks: array[MaxEdges, uint64]
  var internal: array[MaxEdges, uint64]
  var internalCount = 0
  let universe = (1'u64 shl n) - 1
  for edge in 0 ..< edges:
    let raw = input[offset + edge]
    if raw <= 0 or uint64(raw) >= universe or (raw and 1) != 0: return false
    masks[edge] = uint64(raw)
    for earlier in 0 ..< edge:
      if masks[earlier] == masks[edge]: return false
    let size = bitCount(masks[edge], n)
    if size == 1 or size == n - 1:
      if size == n - 1 and masks[edge] != (universe xor 1'u64): return false
    elif size >= 2 and size <= n - 2:
      internal[internalCount] = masks[edge]
      inc internalCount
    else:
      return false
  if internalCount != n - 3: return false
  for leaf in 1 ..< n:
    let pendant = 1'u64 shl leaf
    var found = 0
    for edge in 0 ..< edges:
      if masks[edge] == pendant: inc found
    if found != 1: return false
  var rootPendant = 0
  for edge in 0 ..< edges:
    if masks[edge] == (universe xor 1'u64): inc rootPendant
  if rootPendant != 1: return false
  for i in 0 ..< internalCount:
    for j in i + 1 ..< internalCount:
      let intersection = internal[i] and internal[j]
      if intersection != 0 and intersection != internal[i] and intersection != internal[j]: return false
  true

proc non_shared_edges*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "non_shared_edges".} =
  if input.isNil or length < csize_t(7) or length > csize_t(MaxInput): return -1
  let leafValue = input[0]
  if leafValue < 3 or leafValue > MaxLeaves: return -1
  let leaves = int(leafValue)
  let edges = 2 * leaves - 3
  if int(length) != 1 + 2 * edges: return -1
  let second = 1 + edges
  if not validTree(input, 1, leaves, edges) or not validTree(input, second, leaves, edges): return -1
  var shared = 0'i64
  for left in 0 ..< edges:
    for right in 0 ..< edges:
      if input[1 + left] == input[second + right]:
        inc shared
        break
  if output.isNil or capacity < csize_t(8): return -2
  var staged: array[8, uint8]
  storeI64Le(addr staged[0], int64(edges) - shared)
  for byte in 0 ..< 8: output[byte] = staged[byte]
  8
