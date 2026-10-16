## Count exact covers and emit selected-row bitmasks in ascending order.
proc dancing_links*(input: ptr UncheckedArray[int64], length: csize_t,
                    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "dancing_links".} =
  if input.isNil or length < 2: return -1
  let universeValue = input[0]
  let rowCountValue = input[1]
  if universeValue < 1 or universeValue > 8 or rowCountValue < 0 or rowCountValue > 8: return -1
  let universe = int(universeValue)
  let rowCount = int(rowCountValue)
  if length != csize_t(rowCount + 2): return -1
  let fullMask = (1'i64 shl universe) - 1
  for row in 0 ..< rowCount:
    let mask = input[row + 2]
    if mask <= 0 or (mask and (not fullMask)) != 0: return -1
  let selectionLimit = 1 shl rowCount
  var solutionCount = 0
  for selection in 0 ..< selectionLimit:
    var covered = 0'i64
    var valid = true
    for row in 0 ..< rowCount:
      if (selection and (1 shl row)) == 0: continue
      let mask = input[row + 2]
      if (covered and mask) != 0:
        valid = false
        break
      covered = covered or mask
    if valid and covered == fullMask: inc solutionCount
  if outputCapacity < csize_t(solutionCount) or (solutionCount > 0 and output.isNil): return -2
  var position = 0
  for selection in 0 ..< selectionLimit:
    var covered = 0'i64
    var valid = true
    for row in 0 ..< rowCount:
      if (selection and (1 shl row)) == 0: continue
      let mask = input[row + 2]
      if (covered and mask) != 0:
        valid = false
        break
      covered = covered or mask
    if valid and covered == fullMask:
      output[position] = uint8(selection)
      inc position
  int64(solutionCount)
