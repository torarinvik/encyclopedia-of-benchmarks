const Lines: array[8, array[3, int]] = [
  [0, 1, 2], [3, 4, 5], [6, 7, 8], [0, 3, 6],
  [1, 4, 7], [2, 5, 8], [0, 4, 8], [2, 4, 6]]

proc won(board: array[9, int64], player: int64): bool =
  for line in Lines:
    if board[line[0]] == player and board[line[1]] == player and board[line[2]] == player: return true
  return false

proc search(board: var array[9, int64], side: int64): int =
  if won(board, 1) or won(board, 2): return -1
  var available = false
  for cell in board:
    if cell == 0: available = true
  if not available: return -1
  let other = 3'i64 - side
  var bestRank = -1
  var bestScore = 0
  var bestMask = 0
  for i in 0 ..< 9:
    if board[i] != 0: continue
    board[i] = side
    var score: int
    if won(board, 1): score = 1
    elif won(board, 2): score = 2
    else:
      let child = search(board, other)
      score = if child < 0: 0 else: child div 512
    board[i] = 0
    let rank = if score == int(side): 2 elif score == 0: 1 else: 0
    if rank > bestRank:
      bestRank = rank; bestScore = score; bestMask = 1 shl i
    elif rank == bestRank: bestMask = bestMask or (1 shl i)
  return bestScore * 512 + bestMask

proc depth_first_search_tic_tac_toe*(values: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "depth_first_search_tic_tac_toe".} =
  if values == nil or length != 10 or (values[0] != 1 and values[0] != 2): return -1
  var board: array[9, int64]
  for i in 0 ..< 9:
    if values[i + 1] < 0 or values[i + 1] > 2: return -1
    board[i] = values[i + 1]
  let result = search(board, values[0])
  return if result < 0: 0 else: int64(1 + result)
