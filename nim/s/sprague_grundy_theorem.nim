const MAX_POSITION = 64
const MAX_MOVE_COUNT = 32
const MAX_MOVE_SIZE = 32'i64
const MAX_INPUT_LENGTH = 34

proc calculateGrundy(position: int, memo: var array[65, int64],
    values: ptr UncheckedArray[int64], moveCount: int): int64 =
  if memo[position] != -1: return memo[position]
  if position == 0:
    memo[0] = 0
    return 0

  var reachable: array[33, bool]
  for index in 0 ..< moveCount:
    let move = int(values[2 + index])
    if move <= position:
      let child = calculateGrundy(position - move, memo, values, moveCount)
      if child >= 0 and child <= int64(MAX_MOVE_COUNT): reachable[int(child)] = true
  var mex = 0
  while mex <= MAX_MOVE_COUNT and reachable[mex]: inc mex
  memo[position] = int64(mex)
  int64(mex)

proc spragueGrundyTheorem*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "sprague_grundy_theorem".} =
  if values == nil or length < 2 or length > csize_t(MAX_INPUT_LENGTH): return -1
  let positionValue = values[0]
  let moveCountValue = values[1]
  if positionValue < 0 or positionValue > MAX_POSITION or
      moveCountValue < 0 or moveCountValue > MAX_MOVE_COUNT: return -1
  let moveCount = int(moveCountValue)
  if length != csize_t(2 + moveCount): return -1
  for index in 0 ..< moveCount:
    if values[2 + index] < 1 or values[2 + index] > MAX_MOVE_SIZE: return -1

  var memo: array[65, int64]
  for index in 0 ..< memo.len: memo[index] = -1
  calculateGrundy(int(positionValue), memo, values, moveCount)
