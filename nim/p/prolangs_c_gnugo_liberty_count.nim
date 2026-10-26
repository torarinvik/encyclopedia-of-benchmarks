## GNU Go 1.1 provenance: Copyright (C) Free Software Foundation, Inc.
## Written by Man L. Li, modified by Wayne Iba, documented by Bob Webber.
## Upstream countlib/count are under GNU GPL version 1; this derivative is licensed under GNU GPL version 1.
proc prolangs_c_gnugo_liberty_count*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc.} =
  if input == nil or length < 4 or length > 726: return -1
  let row = input[0]; let col = input[1]; let color = input[2]; let count = input[3]
  if row < 0 or row >= 19 or col < 0 or col >= 19 or (color != 1 and color != 2) or count < 0 or count > 361: return -1
  if int64(length) != 4 + 2 * count: return -1
  var board: array[361, uint8]
  var seen: array[361, bool]
  var liberties: array[361, bool]
  for k in 0 ..< int(count):
    let at = input[4 + 2*k]; let stone = input[5 + 2*k]
    if at < 0 or at >= 361 or (stone != 1 and stone != 2) or board[int(at)] != 0: return -1
    board[int(at)] = uint8(stone)
  let start = int(row * 19 + col)
  if board[start] != uint8(color): return -1
  var stack: array[361, int]
  var top = 1
  var total = 0'i64
  stack[0] = start; seen[start] = true
  while top > 0:
    dec top
    let at = stack[top]; let r = at div 19; let c = at mod 19
    var neighbors: array[4, int]
    var n = 0
    if r > 0: neighbors[n] = at - 19; inc n
    if r < 18: neighbors[n] = at + 19; inc n
    if c > 0: neighbors[n] = at - 1; inc n
    if c < 18: neighbors[n] = at + 1; inc n
    for j in 0 ..< n:
      let nxt = neighbors[j]
      if board[nxt] == 0'u8:
        if not liberties[nxt]: liberties[nxt] = true; inc total
      elif board[nxt] == uint8(color) and not seen[nxt]:
        seen[nxt] = true; stack[top] = nxt; inc top
  total
