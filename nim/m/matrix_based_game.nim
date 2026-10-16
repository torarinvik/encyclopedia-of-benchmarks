const MaxInputLength = 194
const MaxMoves = 64

type I64Input = ptr UncheckedArray[int64]

proc matrixBasedGameIsSymbol(value: int64): bool =
  (value >= 48 and value <= 57) or
    (value >= 65 and value <= 90) or
    (value >= 97 and value <= 122)

proc matrix_based_game*(values: I64Input, length: csize_t): int64
    {.cdecl, exportc: "matrix_based_game".} =
  if values == nil or length < 2 or length > MaxInputLength: return -1
  let nValue = values[0]
  if nValue < 1 or nValue > 8: return -1
  let n = int(nValue)
  let cells = n * n
  let moveCountIndex = 1 + cells
  if int(length) < moveCountIndex + 1: return -1
  let moveCountValue = values[moveCountIndex]
  if moveCountValue < 0 or moveCountValue > MaxMoves: return -1
  let moveCount = int(moveCountValue)
  if int(length) != 2 + cells + 2 * moveCount: return -1

  var board: array[64, int64]
  var visited: array[64, bool]
  var stack: array[64, int]
  for index in 0 ..< cells:
    if not matrixBasedGameIsSymbol(values[1 + index]): return -1
    board[index] = values[1 + index]
  for movement in 0 ..< moveCount:
    let x = values[moveCountIndex + 1 + 2 * movement]
    let y = values[moveCountIndex + 2 + 2 * movement]
    if x < 0 or x >= nValue or y < 0 or y >= nValue: return -1

  var totalScore = 0'i64
  for movement in 0 ..< moveCount:
    let x = int(values[moveCountIndex + 1 + 2 * movement])
    let y = int(values[moveCountIndex + 2 + 2 * movement])
    let startRow = n - 1 - y
    let start = startRow * n + x
    let color = board[start]
    if color == -1: continue

    for index in 0 ..< cells: visited[index] = false
    var stackCount = 0
    stack[stackCount] = start
    inc stackCount
    visited[start] = true
    var componentSize = 0'i64
    while stackCount > 0:
      dec stackCount
      let current = stack[stackCount]
      let row = current div n
      let col = current mod n
      if row > 0:
        let neighbor = current - n
        if not visited[neighbor] and board[neighbor] == color:
          visited[neighbor] = true
          stack[stackCount] = neighbor
          inc stackCount
      if row + 1 < n:
        let neighbor = current + n
        if not visited[neighbor] and board[neighbor] == color:
          visited[neighbor] = true
          stack[stackCount] = neighbor
          inc stackCount
      if col > 0:
        let neighbor = current - 1
        if not visited[neighbor] and board[neighbor] == color:
          visited[neighbor] = true
          stack[stackCount] = neighbor
          inc stackCount
      if col + 1 < n:
        let neighbor = current + 1
        if not visited[neighbor] and board[neighbor] == color:
          visited[neighbor] = true
          stack[stackCount] = neighbor
          inc stackCount
      board[current] = -1
      inc componentSize
    totalScore += componentSize * (componentSize + 1) div 2

    for col in 0 ..< n:
      var targetRow = n
      var rowCursor = n
      while rowCursor > 0:
        dec rowCursor
        let value = board[rowCursor * n + col]
        if value != -1:
          dec targetRow
          board[targetRow * n + col] = value
      for row in 0 ..< targetRow: board[row * n + col] = -1
    var writeCol = 0
    for col in 0 ..< n:
      var nonempty = false
      for row in 0 ..< n:
        if board[row * n + col] != -1: nonempty = true
      if not nonempty: continue
      if writeCol != col:
        for row in 0 ..< n:
          board[row * n + writeCol] = board[row * n + col]
      inc writeCol
    for col in writeCol ..< n:
      for row in 0 ..< n: board[row * n + col] = -1
  totalScore
