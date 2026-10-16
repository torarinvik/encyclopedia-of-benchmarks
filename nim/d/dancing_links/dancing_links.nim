## Count exact covers with Algorithm X's minimum-column recursion.
proc search(columns, rowCount: int, rows: array[8, uint64], covered, selected: uint64,
            found: var array[256, bool], solutionCount: var int) =
  let fullMask = (1'u64 shl columns) - 1'u64
  if covered == fullMask:
    let index = int(selected)
    if not found[index]:
      found[index] = true
      inc solutionCount
    return
  var bestColumn = columns
  var bestCount = rowCount + 1
  for column in 0 ..< columns:
    let bit = 1'u64 shl column
    if (covered and bit) != 0: continue
    var candidates = 0
    for row in 0 ..< rowCount:
      if (rows[row] and bit) != 0 and (rows[row] and covered) == 0:
        inc candidates
    if candidates == 0: return
    if candidates < bestCount:
      bestColumn = column
      bestCount = candidates
  let bit = 1'u64 shl bestColumn
  for row in 0 ..< rowCount:
    if (rows[row] and bit) != 0 and (rows[row] and covered) == 0:
      search(columns, rowCount, rows, covered or rows[row],
             selected or (1'u64 shl row), found, solutionCount)

proc dancing_links*(input: ptr UncheckedArray[int64], length: csize_t,
                    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "dancing_links".} =
  if input.isNil or length < 2 or length > 10: return -1
  let universeValue = input[0]
  let rowCountValue = input[1]
  if universeValue < 1 or universeValue > 8 or rowCountValue < 0 or rowCountValue > 8: return -1
  let universe = int(universeValue)
  let rowCount = int(rowCountValue)
  if length != csize_t(rowCount + 2): return -1
  let fullMask = (1'i64 shl universe) - 1
  var rows: array[8, uint64] = default(array[8, uint64])
  for row in 0 ..< rowCount:
    let mask = input[row + 2]
    if mask <= 0 or (mask and (not fullMask)) != 0: return -1
    rows[row] = uint64(mask)
  var found: array[256, bool] = default(array[256, bool])
  var solutionCount = 0
  search(universe, rowCount, rows, 0, 0, found, solutionCount)
  if outputCapacity < csize_t(solutionCount) or (solutionCount > 0 and output.isNil): return -2
  var position = 0
  for selection in 0 ..< 256:
    if found[selection]:
      output[position] = uint8(selection)
      inc position
  int64(solutionCount)
