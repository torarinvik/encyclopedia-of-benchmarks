const
  MaxRows = 8
  MaxColumns = 10
  MaxInput = 21
  Inf = 1_000_000'i64

proc storeI64Le(output: ptr UncheckedArray[uint8], value: int64) =
  var bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[byte] = uint8(bits and 255)
    bits = bits shr 8

proc solve(rows, columns: int, weights: array[MaxColumns, int64],
           rowLeft, rowRight: array[MaxRows, int]): int64 =
  var order: array[MaxRows, int]
  for row in 0 ..< rows: order[row] = row
  for i in 1 ..< rows:
    let value = order[i]
    var j = i
    while j > 0 and rowLeft[order[j - 1]] > rowLeft[value]:
      order[j] = order[j - 1]
      dec j
    order[j] = value

  var groupedLeft, groupedRight: array[MaxRows, int]
  var groups = 0
  for i in 0 ..< rows:
    let row = order[i]
    if groups == 0 or groupedLeft[groups - 1] != rowLeft[row]:
      groupedLeft[groups] = rowLeft[row]
      groupedRight[groups] = rowRight[row]
      inc groups
    elif rowRight[row] < groupedRight[groups - 1]:
      groupedRight[groups - 1] = rowRight[row]

  var retainedLeft, retainedRight: array[MaxRows, int]
  var retained = 0
  var suffixMinimum = columns
  for offset in 0 ..< groups:
    let i = groups - 1 - offset
    if groupedRight[i] < suffixMinimum:
      retainedLeft[retained] = groupedLeft[i]
      retainedRight[retained] = groupedRight[i]
      inc retained
      suffixMinimum = groupedRight[i]

  var columnStart, columnEnd: array[MaxColumns, int]
  for column in 0 ..< columns:
    columnStart[column] = -1
    columnEnd[column] = -1
  for reducedRow in 0 ..< retained:
    let source = retained - 1 - reducedRow
    for column in retainedLeft[source] .. retainedRight[source]:
      if columnStart[column] < 0: columnStart[column] = reducedRow
      columnEnd[column] = reducedRow

  var distance: array[MaxColumns, int64]
  for column in 0 ..< columns:
    distance[column] = Inf
    if columnStart[column] == 0: distance[column] = 0
  var best = Inf
  for fromColumn in 0 ..< columns:
    if distance[fromColumn] == Inf: continue
    if columnEnd[fromColumn] == retained - 1:
      best = min(best, distance[fromColumn] + weights[fromColumn])
    for toColumn in fromColumn + 1 ..< columns:
      if columnStart[toColumn] >= 0 and columnStart[toColumn] <= columnEnd[fromColumn] + 1:
        distance[toColumn] = min(distance[toColumn], distance[fromColumn] + weights[fromColumn])
  if best == Inf: -1 else: best

proc strong_c1p_set_cover_shortest_path*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "strong_c1p_set_cover_shortest_path".} =
  if input == nil or length < 4 or length > csize_t(MaxInput): return -1
  let rowsRaw = input[0]
  let columnsRaw = input[1]
  if rowsRaw < 1 or rowsRaw > MaxRows or columnsRaw < 1 or columnsRaw > MaxColumns: return -1
  let rows = int(rowsRaw)
  let columns = int(columnsRaw)
  if int(length) != 2 + rows + columns: return -1
  var weights: array[MaxColumns, int64]
  for column in 0 ..< columns:
    let weight = input[2 + column]
    if weight < 1 or weight > 20: return -1
    weights[column] = weight
  let allowed = (1'u64 shl columns) - 1
  var masks: array[MaxRows, uint64]
  var rowLeft, rowRight: array[MaxRows, int]
  var infeasible = false
  for row in 0 ..< rows:
    let raw = input[2 + columns + row]
    if raw < 0 or (uint64(raw) and not allowed) != 0: return -1
    masks[row] = uint64(raw)
    rowLeft[row] = columns
    rowRight[row] = -1
    var seenOne = false
    var seenZeroAfter = false
    for column in 0 ..< columns:
      if (masks[row] and (1'u64 shl column)) != 0:
        if seenZeroAfter: return -1
        seenOne = true
        if rowLeft[row] == columns: rowLeft[row] = column
        rowRight[row] = column
      elif seenOne:
        seenZeroAfter = true
    if masks[row] == 0: infeasible = true
  let result = if infeasible: -1'i64 else: solve(rows, columns, weights, rowLeft, rowRight)
  if output == nil or capacity < 8: return -2
  storeI64Le(output, result)
  8
