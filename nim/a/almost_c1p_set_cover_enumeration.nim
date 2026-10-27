const MaxRows = 8
const MaxColumns = 10
const MaxOutputBytes = 80

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc almost_c1p_set_cover_enumeration*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "almost_c1p_set_cover_enumeration".} =
  if input.isNil or length < csize_t(4) or length > csize_t(21): return -1
  let rowsRaw = input[0]
  let columnsRaw = input[1]
  if rowsRaw < 1 or rowsRaw > MaxRows or columnsRaw < 1 or columnsRaw > MaxColumns or
      length != csize_t(2 + rowsRaw + columnsRaw): return -1
  let rows = int(rowsRaw)
  let columns = int(columnsRaw)
  var weights: array[MaxColumns, int64]
  for column in 0 ..< columns:
    let weight = input[2 + column]
    if weight < 1 or weight > 20: return -1
    weights[column] = weight
  let validMask = (1'u64 shl columns) - 1'u64
  var rowMasks: array[MaxRows, uint64]
  for row in 0 ..< rows:
    let raw = input[2 + columns + row]
    if raw < 0 or (cast[uint64](raw) and not validMask) != 0: return -1
    rowMasks[row] = cast[uint64](raw)

  let stateCount = 1 shl columns
  var feasible: array[1 shl MaxColumns, bool]
  feasible[0] = true
  for row in 0 ..< rows:
    let coverMask = rowMasks[row]
    for selected in 0 ..< stateCount:
      if not feasible[selected] or (uint64(selected) and coverMask) != 0: continue
      feasible[selected] = false
      for column in 0 ..< columns:
        let bit = 1'u64 shl column
        if (coverMask and bit) != 0: feasible[selected or (1 shl column)] = true

  var bestFound = false
  var bestMask = 0'u64
  var bestCost = 0'i64
  for selected in 0 ..< stateCount:
    if not feasible[selected]: continue
    var cost = 0'i64
    for column in 0 ..< columns:
      if (selected and (1 shl column)) != 0: cost += weights[column]
    let mask = uint64(selected)
    if not bestFound or cost < bestCost or (cost == bestCost and mask < bestMask):
      bestFound = true
      bestMask = mask
      bestCost = cost
  var selectedCount = 0
  if bestFound:
    for column in 0 ..< columns:
      if (bestMask and (1'u64 shl column)) != 0: inc selectedCount
  let outputBytes = if bestFound: 8 * (selectedCount + 2) else: 8
  if output.isNil or capacity < csize_t(outputBytes): return -2
  var staged: array[MaxOutputBytes, uint8]
  if bestFound:
    storeI64Le(addr staged[0], 0, int64(selectedCount))
    var cursor = 1
    for column in 0 ..< columns:
      if (bestMask and (1'u64 shl column)) != 0:
        storeI64Le(addr staged[0], 8 * cursor, int64(column))
        inc cursor
    storeI64Le(addr staged[0], 8 * cursor, bestCost)
  else:
    storeI64Le(addr staged[0], 0, -1)
  for byte in 0 ..< outputBytes: output[byte] = staged[byte]
  int64(outputBytes)
