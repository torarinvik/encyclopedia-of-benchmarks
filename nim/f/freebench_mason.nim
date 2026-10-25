type
  State = array[9, int]

const MaxDepth = 8
const UpperMoves: array[3, array[18, int]] = [
  [0, 8, 1, 2, 16, 5, 13, 7, 14, 9, 3, 4, 11, 12, 15, 10, 17, 6],
  [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17],
  [1, 2, 9, 10, 4, 17, 6, 0, 8, 15, 11, 12, 5, 13, 7, 14, 3, 16]
]
const LowerMoves: array[3, array[18, int]] = [
  [0, 2, 3, 10, 11, 5, 17, 7, 1, 9, 15, 12, 13, 6, 8, 14, 4, 16],
  [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17],
  [7, 0, 1, 16, 4, 12, 6, 14, 8, 2, 3, 10, 11, 13, 15, 9, 17, 5]
]
const NearMask: array[18, int] = [
  0x50, 0x70, 0x70, 0x75, 0x0f, 0x0f, 0x0f, 0x70, 0x70,
  0x70, 0x7d, 0x2b, 0x2f, 0x0f, 0x50, 0x64, 0x67, 0x0f
]

proc nearEnough(state: State): bool =
  (NearMask[state[1]] and 0x02) != 0 and
    (NearMask[state[3]] and 0x08) != 0 and
    (NearMask[state[4]] and 0x10) != 0 and
    (NearMask[state[5]] and 0x20) != 0 and
    (NearMask[state[0]] and 0x01) != 0 and
    (NearMask[state[2]] and 0x04) != 0 and
    (NearMask[state[6]] and 0x40) != 0 and
    (NearMask[state[7]] and 0x40) != 0 and
    (NearMask[state[8]] and 0x40) != 0

proc isGoal(state: State): bool =
  state[0] == 5 and state[1] == 6 and state[2] == 12 and
    state[3] == 13 and state[4] == 14 and state[5] == 15 and
    state[6] + state[7] + state[8] == 3

proc applyMove(state: State, map: array[18, int]): State =
  var next: State
  for piece in 0 ..< 9:
    next[piece] = map[state[piece]]
  next

proc searchDown(state: State, bound, depth, lastMove: int): bool

proc searchUp(state: State, bound, depth, lastMove: int): bool =
  if depth == bound - 4 and not nearEnough(state): return false
  if isGoal(state): return true
  if bound <= depth: return false
  for movement in 0 ..< 3:
    if movement == lastMove: continue
    let next = applyMove(state, UpperMoves[movement])
    if searchDown(next, bound, depth + 1, movement): return true
  false

proc searchDown(state: State, bound, depth, lastMove: int): bool =
  if bound <= depth: return false
  for movement in 0 ..< 3:
    if movement == lastMove: continue
    let next = applyMove(state, LowerMoves[movement])
    if searchUp(next, bound, depth + 1, movement): return true
  false

proc freebench_mason*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "freebench_mason".} =
  if input == nil or length != 9: return -1
  var start: State
  var used = 0'u32
  for piece in 0 ..< 9:
    let position = input[piece]
    if position < 0 or position >= 18: return -1
    let bit = 1'u32 shl int(position)
    if (used and bit) != 0: return -1
    used = used or bit
    start[piece] = int(position)
  for bound in countup(2, MaxDepth, 2):
    if searchUp(start, bound, 0, -1): return int64(bound)
  -2
