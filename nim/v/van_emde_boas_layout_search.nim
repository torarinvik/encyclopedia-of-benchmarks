const
  MaxHeight = 4
  MaxNodes = 15
  MaxQueries = 4
  MaxWords = 41
  MaxParseable = 2 + MaxQueries + 1

proc fillKeys(keys: var array[MaxNodes + 1, int64], heap: int,
              low, high: int64) =
  if low > high: return
  let middle = low + (high - low) div 2
  keys[heap] = middle
  fillKeys(keys, heap * 2, low, middle - 1)
  fillKeys(keys, heap * 2 + 1, middle + 1, high)

proc emitLayout(order: var array[MaxNodes, int64], used: var int,
                root, height: int) =
  if height == 1:
    order[used] = int64(root)
    inc used
    return
  let topHeight = height div 2
  let bottomHeight = height - topHeight
  emitLayout(order, used, root, topHeight)
  let bottomCount = 1 shl topHeight
  for offset in 0 ..< bottomCount:
    emitLayout(order, used, root * bottomCount + offset, bottomHeight)

proc validInput(input: ptr UncheckedArray[int64], length: int): int =
  if input.isNil or length < 2 or length > MaxParseable: return -1
  let heightValue = input[0]
  let queryValue = input[1]
  if heightValue < 1 or heightValue > int64(MaxHeight) or
     queryValue < 0 or queryValue > int64(MaxQueries): return -1
  let height = int(heightValue)
  let queryCount = int(queryValue)
  if length != 2 + queryCount: return -1
  let nodeCount = (1 shl height) - 1
  for query in 0 ..< queryCount:
    if input[2 + query] < -1 or input[2 + query] > int64(nodeCount): return -1
  queryCount

proc van_emde_boas_layout_search*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "van_emde_boas_layout_search".} =
  if input.isNil or length < 2 or length > csize_t(MaxParseable): return -1
  let queryCount = validInput(input, int(length))
  if queryCount < 0: return -1
  let height = int(input[0])
  let nodeCount = (1 shl height) - 1
  var order: array[MaxNodes, int64]
  var keys: array[MaxNodes + 1, int64]
  var slots: array[MaxNodes + 1, int64]
  var staged: array[MaxWords, int64]
  var used = 0
  emitLayout(order, used, 1, height)
  fillKeys(keys, 1, 0, int64(nodeCount - 1))
  for slot in 0 ..< nodeCount:
    slots[int(order[slot])] = int64(slot)

  var out = 0
  staged[out] = int64(nodeCount)
  inc out
  for slot in 0 ..< nodeCount:
    staged[out] = order[slot]
    inc out
  staged[out] = int64(queryCount)
  inc out
  for query in 0 ..< queryCount:
    let key = input[2 + query]
    var heap = 1
    let pathStart = out
    inc out
    var pathLength = 0
    var found = -1'i64
    while heap <= nodeCount:
      staged[out] = slots[heap]
      inc out
      inc pathLength
      if key == keys[heap]:
        found = int64(heap)
        break
      if key < keys[heap]: heap *= 2
      else: heap = heap * 2 + 1
    staged[pathStart] = int64(pathLength)
    staged[out] = found
    inc out
  let required = out * 8
  if output.isNil or capacity < csize_t(required): return -2
  for word in 0 ..< out:
    let bits = cast[uint64](staged[word])
    for byte in 0 ..< 8:
      output[word * 8 + byte] = uint8((bits shr (8 * byte)) and 0xff'u64)
  int64(required)
