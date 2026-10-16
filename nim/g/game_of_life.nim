## Compute one finite, non-wrapping Conway Game of Life generation.
const MaxSide = 32

proc game_of_life*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "game_of_life".} =
  if length == 0 or input == nil: return -1
  let sideValue = input[0]
  if sideValue < 0 or sideValue > MaxSide: return -1
  let side = int(sideValue)
  let cellCount = side * side
  if length != csize_t(cellCount + 1): return -1
  for index in 0 ..< cellCount:
    if input[index + 1] != 0 and input[index + 1] != 1: return -1
  if outputCapacity < csize_t(cellCount) or (cellCount > 0 and output == nil): return -2

  for row in 0 ..< side:
    for column in 0 ..< side:
      var neighbors = 0
      for rowDelta in -1 .. 1:
        for columnDelta in -1 .. 1:
          if rowDelta == 0 and columnDelta == 0: continue
          let neighborRow = row + rowDelta
          let neighborColumn = column + columnDelta
          if neighborRow >= 0 and neighborRow < side and
              neighborColumn >= 0 and neighborColumn < side and
              input[1 + neighborRow * side + neighborColumn] == 1:
            inc neighbors
      let alive = input[1 + row * side + column] == 1
      output[row * side + column] = uint8((alive and (neighbors == 2 or neighbors == 3)) or
                                           (not alive and neighbors == 3))
  int64(cellCount)
