const
  MaxRows = 8
  MaxColumns = 8
  MaxInput = 19
  MaxOutput = 272

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  var bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8(bits and 255)
    bits = bits shr 8

proc columnCoverage(masks: array[MaxRows, uint64], activeRows: array[MaxRows, bool],
                    rows, column: int): uint64 =
  for row in 0 ..< rows:
    if activeRows[row] and (masks[row] and (1'u64 shl column)) != 0:
      result = result or (1'u64 shl row)

proc set_cover_domination_reduction*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "set_cover_domination_reduction".} =
  if input == nil or length < 4 or length > csize_t(MaxInput): return -1
  let rowsRaw = input[0]
  let columnsRaw = input[1]
  if rowsRaw < 1 or rowsRaw > MaxRows or columnsRaw < 1 or columnsRaw > MaxColumns or
      int(length) != 2 + int(rowsRaw) + int(columnsRaw): return -1
  let rows = int(rowsRaw)
  let columns = int(columnsRaw)
  var weights: array[MaxColumns, int64]
  var activeColumns: array[MaxColumns, bool]
  for column in 0 ..< columns:
    let weight = input[2 + column]
    if weight < 1 or weight > 20: return -1
    weights[column] = weight
    activeColumns[column] = true
  let validColumns = (1'u64 shl columns) - 1
  var masks: array[MaxRows, uint64]
  var activeRows: array[MaxRows, bool]
  for row in 0 ..< rows:
    let raw = input[2 + columns + row]
    if raw < 0 or (uint64(raw) and not validColumns) != 0: return -1
    masks[row] = uint64(raw)
    activeRows[row] = true

  while true:
    var changed = false
    for keep in 0 ..< rows:
      if not activeRows[keep]: continue
      for drop in 0 ..< rows:
        if not activeRows[drop] or keep == drop: continue
        if (masks[keep] and not masks[drop]) == 0 and (masks[keep] != masks[drop] or keep < drop):
          activeRows[drop] = false
          changed = true
          break
      if changed: break
    if changed: continue

    for drop in 0 ..< columns:
      if not activeColumns[drop]: continue
      let dropCover = columnCoverage(masks, activeRows, rows, drop)
      for keep in 0 ..< columns:
        if not activeColumns[keep] or keep == drop: continue
        let keepCover = columnCoverage(masks, activeRows, rows, keep)
        if (dropCover and not keepCover) == 0 and weights[drop] >= weights[keep] and
            (dropCover != keepCover or weights[drop] != weights[keep] or keep < drop):
          activeColumns[drop] = false
          for row in 0 ..< rows: masks[row] = masks[row] and not (1'u64 shl drop)
          changed = true
          break
      if changed: break
    if changed: continue

    for drop in 0 ..< columns:
      if not activeColumns[drop]: continue
      let dropCover = columnCoverage(masks, activeRows, rows, drop)
      for keep in 0 ..< columns:
        if not activeColumns[keep] or keep == drop: continue
        let keepCover = columnCoverage(masks, activeRows, rows, keep)
        let exclusiveRows = dropCover and not keepCover
        if (dropCover and keepCover) == 0 or exclusiveRows == 0: continue
        var replacementColumns = 0'u64
        var feasible = true
        for row in 0 ..< rows:
          if (exclusiveRows and (1'u64 shl row)) == 0: continue
          var minimumColumn = -1
          for candidate in 0 ..< columns:
            if not activeColumns[candidate] or (masks[row] and (1'u64 shl candidate)) == 0: continue
            if minimumColumn < 0 or weights[candidate] < weights[minimumColumn] or
                (weights[candidate] == weights[minimumColumn] and candidate < minimumColumn):
              minimumColumn = candidate
          if minimumColumn < 0:
            feasible = false
            break
          replacementColumns = replacementColumns or (1'u64 shl minimumColumn)
        var replacementCost = weights[keep]
        for candidate in 0 ..< columns:
          if (replacementColumns and (1'u64 shl candidate)) != 0: replacementCost += weights[candidate]
        if feasible and weights[drop] >= replacementCost:
          activeColumns[drop] = false
          for row in 0 ..< rows: masks[row] = masks[row] and not (1'u64 shl drop)
          changed = true
          break
      if changed: break
    if not changed: break

  var rowIds: array[MaxRows, int]
  var columnIds: array[MaxColumns, int]
  var rowCount = 0
  var columnCount = 0
  for row in 0 ..< rows:
    if activeRows[row]: rowIds[rowCount] = row; inc rowCount
  for column in 0 ..< columns:
    if activeColumns[column]: columnIds[columnCount] = column; inc columnCount
  var reducedMasks: array[MaxRows, uint64]
  for i in 0 ..< rowCount:
    for j in 0 ..< columnCount:
      if (masks[rowIds[i]] and (1'u64 shl columnIds[j])) != 0:
        reducedMasks[i] = reducedMasks[i] or (1'u64 shl j)
  let words = 2 + 2 * rowCount + 2 * columnCount
  let byteCount = 8 * words
  var staged: array[MaxOutput, uint8]
  var cursor = 0
  storeI64Le(cast[ptr UncheckedArray[uint8]](addr staged[0]), 8 * cursor, int64(rowCount)); inc cursor
  storeI64Le(cast[ptr UncheckedArray[uint8]](addr staged[0]), 8 * cursor, int64(columnCount)); inc cursor
  for i in 0 ..< rowCount:
    storeI64Le(cast[ptr UncheckedArray[uint8]](addr staged[0]), 8 * cursor, int64(rowIds[i])); inc cursor
  for i in 0 ..< columnCount:
    storeI64Le(cast[ptr UncheckedArray[uint8]](addr staged[0]), 8 * cursor, int64(columnIds[i])); inc cursor
  for i in 0 ..< columnCount:
    storeI64Le(cast[ptr UncheckedArray[uint8]](addr staged[0]), 8 * cursor, weights[columnIds[i]]); inc cursor
  for i in 0 ..< rowCount:
    storeI64Le(cast[ptr UncheckedArray[uint8]](addr staged[0]), 8 * cursor, cast[int64](reducedMasks[i])); inc cursor
  if output == nil or capacity < csize_t(byteCount): return -2
  for byte in 0 ..< byteCount: output[byte] = staged[byte]
  int64(byteCount)
