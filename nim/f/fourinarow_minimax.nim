const
  MaxHistory = 20
  MaxDepth = 7'i64
  HugeScore = 100000
  C4V = (1'u64 shl 0) or (1'u64 shl 7) or (1'u64 shl 14) or (1'u64 shl 21)
  C3V = C4V shr 7
  C2V = C3V shr 7
  C4H = 15'u64
  C3H = C4H shr 1
  C2H = C3H shr 1
  C4UR = (1'u64 shl 0) or (1'u64 shl 8) or (1'u64 shl 16) or (1'u64 shl 24)
  C3UR = C4UR shr 8
  C2UR = C3UR shr 8
  C4UL = (1'u64 shl 3) or (1'u64 shl 9) or (1'u64 shl 15) or (1'u64 shl 21)
  C3UL = C4UL shr 6
  C2UL = C3UL shr 6

proc has(board, mask: uint64): bool = (board and mask) == mask

proc scoreBoard(human, computer: uint64): int =
  var total = 0
  for player in 0 ..< 2:
    let b = if player == 0: human else: computer
    let other = if player == 0: computer else: human
    let sign = if player == 0: -1 else: 1
    for i in 0 ..< 21:
      if has(b, C4V shl i): total += sign * 1000
    for i in 0 ..< 6:
      for j in 0 ..< 4:
        if has(b, C4H shl (j + i * 6)): total += sign * 1000
    for i in 0 ..< 3:
      for j in 0 ..< 4:
        if has(b, C4UR shl (j + i * 6)): total += sign * 1000
        if has(b, C4UL shl (j + i * 6)): total += sign * 1000
    for i in 0 ..< 21:
      if has(b, C3V shl i) and (other and (C4V shl i)) == 0: total += sign * 20
    for i in 0 ..< 6:
      for j in 0 ..< 5:
        if has(b, C3H shl (j + i * 6)): total += sign * 20
    for i in 0 ..< 3:
      for j in 0 ..< 4:
        if has(b, C3UR shl (j + i * 6)): total += sign * 20
        if has(b, C3UL shl (j + i * 6)): total += sign * 20
    for i in 0 ..< 21:
      if has(b, C2V shl i) and (other and (C4V shl i)) == 0: total += sign * 5
    for i in 0 ..< 6:
      for j in 0 ..< 6:
        if has(b, C2H shl (j + i * 6)): total += sign * 5
    for i in 0 ..< 3:
      for j in 0 ..< 4:
        if has(b, C2UR shl (j + i * 6)): total += sign * 5
        if has(b, C2UL shl (j + i * 6)): total += sign * 5
  total

proc wins(board: uint64): bool =
  for row in 0 ..< 6:
    for col in 0 ..< 7:
      for dc in 0 .. 1:
        for dr in -1 .. 1:
          if dc == 0 and dr <= 0: continue
          let ec = col + 3 * dc
          let er = row + 3 * dr
          if ec >= 7 or er < 0 or er >= 6: continue
          var line = 0'u64
          for k in 0 ..< 4:
            line = line or (1'u64 shl (col + k * dc + (row + k * dr) * 7))
          if (board and line) == line: return true
  false

proc search(human, computer: uint64, side, level, limit, mode, alpha, beta: int): int =
  if level >= limit: return scoreBoard(human, computer)
  if side == 2:
    var best = -HugeScore
    for col in 0 ..< 7:
      var row = 0
      while row < 6 and ((human or computer) and (1'u64 shl (col + row * 7))) != 0: inc row
      if row == 6: continue
      let value = search(human, computer or (1'u64 shl (col + row * 7)), 1, level + 1, limit, mode, best, beta)
      if value > best: best = value
      if mode == 2 and best > beta: return best
    return best
  var best = HugeScore
  for col in 0 ..< 7:
    var row = 0
    while row < 6 and ((human or computer) and (1'u64 shl (col + row * 7))) != 0: inc row
    if row == 6: continue
    let value = search(human or (1'u64 shl (col + row * 7)), computer, 2, level + 1, limit, mode, alpha, best)
    if value <= best: best = value
    if mode == 2 and best < alpha: return best
  best

proc evaluate(human, computer: uint64, side, depth, mode: int): int64 =
  var best = if side == 2: -HugeScore else: HugeScore
  var bestCol = 0
  for col in 0 ..< 7:
    var row = 0
    while row < 6 and ((human or computer) and (1'u64 shl (col + row * 7))) != 0: inc row
    if row == 6: continue
    let value = if side == 2:
      search(human, computer or (1'u64 shl (col + row * 7)), 1, 2, depth, mode, best, HugeScore)
    else:
      search(human or (1'u64 shl (col + row * 7)), computer, 2, 2, depth, mode, -HugeScore, best)
    if (side == 2 and value > best) or (side == 1 and value <= best):
      best = value
      bestCol = col
  int64(best) * 8 + int64(bestCol)

proc fourinarow_minimax*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "fourinarow_minimax".} =
  if input == nil or length < 4 or length > csize_t(4 + MaxHistory): return -1
  let depth = input[0]
  let mode = input[1]
  let side = input[2]
  let count = input[3]
  if depth < 2 or depth > MaxDepth or (mode != 0 and mode != 2) or (side != 1 and side != 2) or
      count < 0 or count > MaxHistory or length != csize_t(4 + count) or
      side != (if count mod 2 == 0: 1 else: 2): return -1
  var human = 0'u64
  var computer = 0'u64
  var heights: array[7, int]
  for turn in 0 ..< int(count):
    let colValue = input[4 + turn]
    if colValue < 0 or colValue >= 7: return -1
    let col = int(colValue)
    if heights[col] >= 6: return -1
    let bit = 1'u64 shl (col + heights[col] * 7)
    if turn mod 2 == 0: human = human or bit else: computer = computer or bit
    inc heights[col]
    if wins(if turn mod 2 == 0: human else: computer): return -1
  evaluate(human, computer, int(side), int(depth), int(mode))
