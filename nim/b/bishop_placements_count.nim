const MaxN = 8
const MaxK = 16
const MaxDiagonals = 2 * MaxN

proc diagonalSize(index: int): int =
  if (index and 1) != 0: (index div 4) * 2 + 1 else: ((index - 1) div 4) * 2 + 2

proc colorCounts(k, lastDiagonal: int): array[MaxK + 1, int64] =
  var dp = default(array[MaxDiagonals * (MaxK + 1), int64])
  dp[0] = 1
  dp[MaxK + 1] = 1
  if k >= 1: dp[MaxK + 2] = 1
  for diagonal in 2 .. lastDiagonal:
    dp[diagonal * (MaxK + 1)] = 1
    let squares = int64(diagonalSize(diagonal))
    for placed in 1 .. k:
      let offset = diagonal * (MaxK + 1) + placed
      let previous = (diagonal - 2) * (MaxK + 1)
      dp[offset] = dp[previous + placed] + dp[previous + placed - 1] * (squares - int64(placed) + 1)
  for placed in 0 .. k:
    result[placed] = dp[lastDiagonal * (MaxK + 1) + placed]

proc bishop_placements_count*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "bishop_placements_count".} =
  if input.isNil or length != csize_t(2): return -1
  if input[0] < 1 or input[0] > int64(MaxN) or input[1] < 0 or input[1] > int64(MaxK): return -1
  let n = int(input[0])
  let k = int(input[1])
  let maximum = if n == 1: 1 else: 2 * n - 2
  if k > maximum: return 0
  var black, white: array[MaxK + 1, int64]
  black = colorCounts(k, 2 * n - 1)
  white = colorCounts(k, 2 * n - 2)
  var result = 0'i64
  for left in 0 .. k: result += black[left] * white[k - left]
  result
