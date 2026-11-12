import math

const MaxCells = 64
const MaxInput = 132

proc splash2_ocean_rbgs*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64 {.cdecl, exportc: "splash2_ocean_rbgs".} =
  if input == nil or inputLength < 3 or inputLength > csize_t(MaxInput): return -1
  for i in 0 ..< int(inputLength):
    if input[i] != input[i]: return -1
  if input[0] != 4.0 and input[0] != 6.0 and input[0] != 8.0: return -1
  let side = int(input[0])
  let cells = side * side
  if inputLength != csize_t(3 + 2 * cells): return -1
  let eigenvalueSquared = input[1]
  let spacing = input[2]
  if eigenvalueSquared < 0.0 or eigenvalueSquared > 2.0 or spacing < 0.125 or spacing > 1.0:
    return -1
  let factor = 4.0 - eigenvalueSquared * spacing * spacing
  if factor <= 0.0: return -1

  var grid, rhs: array[MaxCells, float64]
  for i in 0 ..< cells:
    grid[i] = input[3 + i]
    rhs[i] = input[3 + cells + i]
    if grid[i] < -8.0 or grid[i] > 8.0 or rhs[i] < -8.0 or rhs[i] > 8.0:
      return -1
  let needed = 1 + cells
  if output == nil or outputCapacity < csize_t(needed): return -2

  var maxChange = 0.0
  for color in 0 .. 1:
    for row in 1 ..< side - 1:
      for column in 1 ..< side - 1:
        if (row + column) mod 2 != color: continue
        let index = row * side + column
        let neighbors = grid[index + 1] + grid[index - 1] + grid[index - side] + grid[index + side]
        let oldValue = grid[index]
        let updated = (neighbors - rhs[index]) / factor
        maxChange = max(maxChange, abs(oldValue - updated))
        grid[index] = updated
  output[0] = maxChange
  for i in 0 ..< cells: output[i + 1] = grid[i]
  int64(needed)
