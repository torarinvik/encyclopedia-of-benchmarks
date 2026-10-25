const ChompColumns = 7

type ChompSolver = object
  rows: int
  powers: array[ChompColumns, int]
  heights: array[ChompColumns, int]
  values: seq[uint8]

proc encodeState(solver: ChompSolver): int =
  for column in 0 ..< ChompColumns:
    result += solver.heights[column] * solver.powers[column]

proc evaluateState(solver: var ChompSolver) =
  let stateId = encodeState(solver)
  var hasMove = false
  var winning = false
  for row in 0 ..< solver.rows:
    for column in 0 ..< ChompColumns:
      var childId = 0
      var changed = false
      for index in 0 ..< ChompColumns:
        var height = solver.heights[index]
        if index >= column and height > row:
          height = row
          changed = true
        childId += height * solver.powers[index]
      if not changed: continue
      hasMove = true
      if solver.values[childId] == 0'u8: winning = true
  var outcome = 1'u8
  if hasMove and not winning: outcome = 0'u8
  solver.values[stateId] = outcome

proc enumerateStates(solver: var ChompSolver, column, minimumHeight: int) =
  if column < 0:
    evaluateState(solver)
    return
  for height in minimumHeight .. solver.rows:
    solver.heights[column] = height
    enumerateStates(solver, column - 1, height)

proc mcgill_chomp*(rows: int64): int64 {.cdecl, exportc: "mcgill_chomp".} =
  if rows != 7 and rows != 8: return -1
  var solver = ChompSolver(rows: int(rows))
  let base = solver.rows + 1
  solver.powers[0] = 1
  for column in 1 ..< ChompColumns:
    solver.powers[column] = solver.powers[column - 1] * base
  let stateSpace = solver.powers[ChompColumns - 1] * base
  solver.values = newSeq[uint8](stateSpace)

  enumerateStates(solver, ChompColumns - 1, 0)
  var fullBoardId = 0
  for column in 0 ..< ChompColumns:
    fullBoardId += solver.rows * solver.powers[column]
  int64(solver.values[fullBoardId])
