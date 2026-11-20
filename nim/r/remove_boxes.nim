const
  MaxBoxes = 18
  MaxParseableLength = MaxBoxes + 2

type Memo = array[MaxBoxes, array[MaxBoxes, array[MaxBoxes + 1, int64]]]

proc solveBoxes(left, right, carry: int, colors: openArray[int64],
                counts: openArray[int], memo: var Memo): int64 =
  if left > right: return 0
  if memo[left][right][carry] >= 0: return memo[left][right][carry]
  let attached = counts[left] + carry
  var best = int64(attached * attached) + solveBoxes(left + 1, right, 0, colors, counts, memo)
  for later in left + 1 .. right:
    if colors[later] == colors[left]:
      let joined = solveBoxes(left + 1, later - 1, 0, colors, counts, memo) +
        solveBoxes(later, right, attached, colors, counts, memo)
      if joined > best: best = joined
  memo[left][right][carry] = best
  best

proc remove_boxes*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "remove_boxes".} =
  if values == nil or length < 1 or length > csize_t(MaxParseableLength): return -1
  if values[0] < 0 or values[0] > int64(MaxBoxes): return -1
  let n = int(values[0])
  if int(length) != n + 1: return -1
  var colors: array[MaxBoxes, int64]
  var counts: array[MaxBoxes, int]
  var groups = 0
  for index in 0 ..< n:
    let color = values[index + 1]
    if color < 0 or color > 7: return -1
    if groups > 0 and colors[groups - 1] == color:
      inc counts[groups - 1]
    else:
      colors[groups] = color
      counts[groups] = 1
      inc groups
  if groups == 0: return 0
  var memo: Memo
  for left in 0 ..< MaxBoxes:
    for right in 0 ..< MaxBoxes:
      for carry in 0 .. MaxBoxes:
        memo[left][right][carry] = -1
  solveBoxes(0, groups - 1, 0, colors, counts, memo)
