##
## Fhourstones 2.0 copyright and distribution notice:
## This software is copyright (c) 1996 by John Tromp, Lindenlaan 33,
## 1701 GT Heerhugowaard, Netherlands. E-mail: tromp@cwi.nl.
## This notice must not be removed. This software must not be sold for profit.
## You may redistribute if your distributees have the same rights and restrictions.
##
## Fhourstones 3.1 copyright and distribution notice:
## This software is copyright (c) 1996-2005 by John Tromp, Insulindeweg 908,
## 1095 DX Amsterdam, Netherlands. E-mail: tromp@cwi.nl.
## This notice must not be removed. This software must not be sold for profit.
## You may redistribute if your distributees have the same rights and restrictions.

const Width = 7
const Height = 6
const BoardCells = 42
const MinMoves = 36
const MaxMoves = 41
const MoveOrder = [3, 2, 4, 1, 5, 0, 6]
const DirX = [1, 0, 1, 1]
const DirY = [0, 1, 1, -1]

proc winsAt(board: array[BoardCells, int], column, row, side: int): bool =
  for direction in 0 ..< 4:
    var count = 1
    for sign in [-1, 1]:
      for step in 1 .. 3:
        let x = column + sign * step * DirX[direction]
        let y = row + sign * step * DirY[direction]
        if x < 0 or x >= Width or y < 0 or y >= Height:
          break
        if board[y * Width + x] != side:
          break
        inc count
    if count >= 4:
      return true
  false

proc solveEndgame(board: var array[BoardCells, int], heights: var array[Width, int],
                  side, remaining, alphaIn, beta: int): int =
  if remaining == 0:
    return 0
  var alpha = alphaIn
  var best = -3
  for column in MoveOrder:
    let row = heights[column]
    if row == Height:
      continue
    board[row * Width + column] = side
    heights[column] = row + 1
    let value = if winsAt(board, column, row, side):
      2
    else:
      -solveEndgame(board, heights, (if side == 1: 2 else: 1), remaining - 1, -beta, -alpha)
    heights[column] = row
    board[row * Width + column] = 0
    if value > best:
      best = value
    if value > alpha:
      alpha = value
    if alpha >= beta:
      break
  best

proc fhourstones_exact*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "fhourstones_exact".} =
  if input == nil or length < 2 or length > 42:
    return -1
  let countValue = input[0]
  if countValue < MinMoves or countValue > MaxMoves:
    return -1
  let count = int(countValue)
  if length != csize_t(count + 1):
    return -1
  var board: array[BoardCells, int]
  var heights: array[Width, int]
  for turn in 0 ..< count:
    let columnValue = input[turn + 1]
    if columnValue < 0 or columnValue >= Width:
      return -1
    let column = int(columnValue)
    let row = heights[column]
    if row >= Height:
      return -1
    let side = if turn mod 2 == 0: 1 else: 2
    board[row * Width + column] = side
    heights[column] = row + 1
    if winsAt(board, column, row, side):
      return -1
  let side = if count mod 2 == 0: 1 else: 2
  int64(solveEndgame(board, heights, side, BoardCells - count, -3, 3))
