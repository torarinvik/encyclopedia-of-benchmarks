type I64Input = ptr UncheckedArray[int64]
type ByteOutput = ptr UncheckedArray[uint8]

const MaxPositions = 960
const MaxInputWords = 962
const KnightFirst: array[10, int] = [0, 0, 0, 0, 1, 1, 1, 2, 2, 3]
const KnightSecond: array[10, int] = [1, 2, 3, 4, 2, 3, 4, 3, 4, 4]

proc unrankPosition(identifier: int64): array[8, uint8] =
  var remainder = uint64(identifier)
  let oddBishop = int(remainder mod 4) * 2 + 1
  remainder = remainder div 4
  let evenBishop = int(remainder mod 4) * 2
  remainder = remainder div 4
  let queenOrdinal = int(remainder mod 6)
  let knightOrdinal = int(remainder div 6)
  var board: array[8, uint8]
  board[oddBishop] = uint8(ord('B'))
  board[evenBishop] = uint8(ord('B'))
  var openFiles: array[8, int]
  var openCount = 0
  for file in 0 ..< 8:
    if board[file] == 0'u8:
      openFiles[openCount] = file
      inc openCount
  board[openFiles[queenOrdinal]] = uint8(ord('Q'))
  openCount = 0
  for file in 0 ..< 8:
    if board[file] == 0'u8:
      openFiles[openCount] = file
      inc openCount
  board[openFiles[KnightFirst[knightOrdinal]]] = uint8(ord('N'))
  board[openFiles[KnightSecond[knightOrdinal]]] = uint8(ord('N'))
  let finalPieces = [uint8(ord('R')), uint8(ord('K')), uint8(ord('R'))]
  var nextPiece = 0
  for file in 0 ..< 8:
    if board[file] == 0'u8:
      board[file] = finalPieces[nextPiece]
      inc nextPiece
  board

proc chess960_scharnagl_position_unrank*(input: I64Input, length: csize_t,
    output: ByteOutput, capacity: csize_t): int64
    {.cdecl, exportc: "chess960_scharnagl_position_unrank".} =
  if input.isNil or length < 1 or length > csize_t(MaxInputWords): return -1
  let countWord = input[0]
  if countWord < 0 or countWord > int64(MaxPositions) or length != csize_t(countWord + 1): return -1
  let count = int(countWord)
  for item in 0 ..< count:
    if input[item + 1] < 0 or input[item + 1] >= int64(MaxPositions): return -1
  let bytes = count * 8
  if bytes > 0 and (output.isNil or capacity < csize_t(bytes)): return -2
  for item in 0 ..< count:
    let board = unrankPosition(input[item + 1])
    for file in 0 ..< 8: output[item * 8 + file] = board[file]
  int64(bytes)
