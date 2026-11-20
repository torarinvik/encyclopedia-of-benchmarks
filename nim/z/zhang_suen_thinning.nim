## Zhang-Suen binary image thinning with simultaneous phase deletions.
const
  MaxRows = 32
  MaxColumns = 32
  MaxCells = 1024
  MaxParseableInputLength = 1027

type PixelBuffer = array[MaxCells, uint8]

proc thinPhase(image: var PixelBuffer, marked: var PixelBuffer,
    rows, columns: int, secondPhase: bool): bool =
  let cells = rows * columns
  for index in 0 ..< cells:
    marked[index] = 0
  var changed = false
  for row in 1 ..< rows - 1:
    for column in 1 ..< columns - 1:
      let index = row * columns + column
      if image[index] == 0: continue
      let p2 = image[index - columns]
      let p3 = image[index - columns + 1]
      let p4 = image[index + 1]
      let p5 = image[index + columns + 1]
      let p6 = image[index + columns]
      let p7 = image[index + columns - 1]
      let p8 = image[index - 1]
      let p9 = image[index - columns - 1]
      let ring = [p2, p3, p4, p5, p6, p7, p8, p9, p2]
      var blackNeighbors = 0
      var transitions = 0
      for neighbor in 0 ..< 8:
        blackNeighbors += int(ring[neighbor])
        if ring[neighbor] == 0 and ring[neighbor + 1] == 1:
          inc transitions
      if blackNeighbors < 2 or blackNeighbors > 6 or transitions != 1: continue
      var blocked: bool
      if secondPhase:
        blocked = (p2 != 0 and p4 != 0 and p8 != 0) or
                  (p2 != 0 and p6 != 0 and p8 != 0)
      else:
        blocked = (p2 != 0 and p4 != 0 and p6 != 0) or
                  (p4 != 0 and p6 != 0 and p8 != 0)
      if blocked: continue
      marked[index] = 1
      changed = true
  if changed:
    for index in 0 ..< cells:
      if marked[index] != 0: image[index] = 0
  changed

proc zhangSuenThinning*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "zhang_suen_thinning".} =
  if input == nil or length < 3 or length > csize_t(MaxParseableInputLength): return -1
  let rowsValue = input[0]
  let columnsValue = input[1]
  if rowsValue < 1 or rowsValue > MaxRows or columnsValue < 1 or columnsValue > MaxColumns:
    return -1
  let rows = int(rowsValue)
  let columns = int(columnsValue)
  let cells = rows * columns
  if length != csize_t(2 + cells): return -1
  for index in 0 ..< cells:
    if input[index + 2] != 0 and input[index + 2] != 1: return -1
  if output == nil or outputCapacity < csize_t(cells): return -2

  var image: PixelBuffer
  var marked: PixelBuffer
  for index in 0 ..< cells: image[index] = uint8(input[index + 2])
  while true:
    let firstChanged = thinPhase(image, marked, rows, columns, false)
    let secondChanged = thinPhase(image, marked, rows, columns, true)
    if not firstChanged and not secondChanged: break
  for index in 0 ..< cells: output[index] = image[index]
  int64(cells)
