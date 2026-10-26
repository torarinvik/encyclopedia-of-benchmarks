## GNU Go 1.1 provenance: Copyright (C) Free Software Foundation, Inc.
## Written by Man L. Li, modified by Wayne Iba, documented by Bob Webber.
## Upstream suicide/eval/countlib/count are under GNU GPL version 1; derivative under GPLv1.
proc groupLiberties(board: array[361, uint8], start: int, color: uint8): int =
  var seen: array[361, bool]
  var libSeen: array[361, bool]
  var stack: array[361, int]
  var top = 1
  var total = 0
  stack[0] = start; seen[start] = true
  while top > 0:
    dec top
    let at = stack[top]; let r = at div 19; let c = at mod 19
    var nb: array[4, int]
    var n = 0
    if r > 0: nb[n] = at - 19; inc n
    if r < 18: nb[n] = at + 19; inc n
    if c > 0: nb[n] = at - 1; inc n
    if c < 18: nb[n] = at + 1; inc n
    for j in 0 ..< n:
      let next = nb[j]
      if board[next] == 0'u8:
        if not libSeen[next]: libSeen[next] = true; inc total
      elif board[next] == color and not seen[next]:
        seen[next] = true; stack[top] = next; inc top
  total

proc prolangs_c_gnugo_suicide*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc.} =
  if input == nil or length < 6 or length > 246: return -1
  let row=input[0]; let col=input[1]; let own=input[2]; let opponent=input[3]; let ko=input[4]; let count=input[5]
  if row < 0 or row >= 19 or col < 0 or col >= 19 or (own != 1 and own != 2) or (opponent != 1 and opponent != 2) or own == opponent or ko < -1 or ko >= 361 or count < 0 or count > 120: return -1
  if int64(length) != 6 + 2*count: return -1
  var board: array[361, uint8]
  for k in 0 ..< int(count):
    let at=input[6+2*k]; let stone=input[7+2*k]
    if at < 0 or at >= 361 or (stone != 1 and stone != 2) or board[int(at)] != 0: return -1
    board[int(at)] = uint8(stone)
  let target = int(row*19+col)
  if board[target] != 0: return -1
  board[target] = uint8(opponent)
  if groupLiberties(board, target, uint8(opponent)) > 0: return 0
  var dead = 0'i64
  for i in 0 ..< 361:
    if board[i] == uint8(own) and groupLiberties(board, i, uint8(own)) == 0: inc dead
  if dead == 0 or (dead == 1 and ko == int64(target)): return 1
  0
