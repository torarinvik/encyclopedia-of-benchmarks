## Sudoku constraint propagation with naked/hidden singles and MRV search.
const
  SudokuCells = 81
  AllDigits = 0x03FE'u16

type CandidateGrid = array[SudokuCells, uint16]

proc isSingle(candidates: uint16): bool =
  candidates != 0 and (candidates and (candidates - 1'u16)) == 0

proc digitFor(candidate: uint16): int =
  result = 1
  while (candidate and (1'u16 shl result)) == 0: inc result

proc assign(candidates: var CandidateGrid, cell: int, selected: uint16): bool

proc eliminate(candidates: var CandidateGrid, cell: int, removed: uint16): bool =
  if (candidates[cell] and removed) == 0: return true
  candidates[cell] = candidates[cell] and not removed
  let remaining = candidates[cell]
  if remaining == 0: return false

  if isSingle(remaining):
    for peer in 0 ..< SudokuCells:
      if peer == cell: continue
      let row = cell div 9
      let column = cell mod 9
      let peerRow = peer div 9
      let peerColumn = peer mod 9
      let sharesRow = row == peerRow
      let sharesColumn = column == peerColumn
      let sharesBox = row div 3 == peerRow div 3 and column div 3 == peerColumn div 3
      if (sharesRow or sharesColumn or sharesBox) and
          not eliminate(candidates, peer, remaining): return false

  let row = cell div 9
  let column = cell mod 9
  let boxRow = row div 3 * 3
  let boxColumn = column div 3 * 3
  for unit in 0 ..< 3:
    var onlyPlace = 0
    var placeCount = 0
    for offset in 0 ..< 9:
      var place: int
      if unit == 0: place = row * 9 + offset
      elif unit == 1: place = offset * 9 + column
      else: place = (boxRow + offset div 3) * 9 + boxColumn + offset mod 3
      if (candidates[place] and removed) != 0:
        onlyPlace = place
        inc placeCount
    if placeCount == 0: return false
    if placeCount == 1 and not assign(candidates, onlyPlace, removed): return false
  true

proc assign(candidates: var CandidateGrid, cell: int, selected: uint16): bool =
  if (candidates[cell] and selected) == 0: return false
  var other = candidates[cell] and not selected
  while other != 0:
    let bit = uint16(int(other) and -int(other))
    other = other and not bit
    if not eliminate(candidates, cell, bit): return false
  true

proc search(candidates: var CandidateGrid): bool =
  var bestCell = SudokuCells
  var bestCount = 10
  for cell in 0 ..< SudokuCells:
    var count = 0
    var bits = candidates[cell]
    while bits != 0:
      inc count
      bits = bits and (bits - 1'u16)
    if count == 0: return false
    if count > 1 and count < bestCount:
      bestCell = cell
      bestCount = count
  if bestCell == SudokuCells: return true

  let choices = candidates[bestCell]
  for digit in 1 .. 9:
    let bit = 1'u16 shl digit
    if (choices and bit) == 0: continue
    var branch = candidates
    if assign(branch, bestCell, bit) and search(branch):
      candidates = branch
      return true
  false

proc sudoku_solver_mrv*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "sudoku_solver_mrv".} =
  if values == nil or length != SudokuCells: return -1
  var candidates: CandidateGrid
  for cell in 0 ..< SudokuCells:
    if values[cell] < 0 or values[cell] > 9: return -1
    candidates[cell] = AllDigits
  for cell in 0 ..< SudokuCells:
    if values[cell] != 0 and
        not assign(candidates, cell, 1'u16 shl int(values[cell])): return -1
  if not search(candidates): return -1
  if output == nil or outputCapacity < 4 * SudokuCells: return -2
  for cell in 0 ..< SudokuCells:
    let digit = uint32(digitFor(candidates[cell]))
    for byte in 0 ..< 4:
      output[cell * 4 + byte] = uint8((digit shr (byte * 8)) and 0xFF'u32)
  SudokuCells.int64
