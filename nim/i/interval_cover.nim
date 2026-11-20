## Greedy minimum subfamily covering a half-open target interval.
proc interval_cover*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "interval_cover".} =
  if input.isNil or length < 3 or length > 36: return -2
  let targetLeft = input[0]
  let targetRight = input[1]
  let countValue = input[2]
  if targetLeft < 0 or targetLeft > targetRight or targetRight > 32 or countValue < 0 or countValue > 16: return -2
  let count = int(countValue)
  if length != csize_t(3 + 2 * count): return -2
  for i in 0 ..< count:
    let left = input[3 + 2 * i]
    let right = input[4 + 2 * i]
    if left < 0 or left >= right or right > 32: return -2
  if targetLeft == targetRight: return 0

  var frontier = targetLeft
  var selected = 0'i64
  while frontier < targetRight:
    var farthest = frontier
    for i in 0 ..< count:
      let left = input[3 + 2 * i]
      let right = input[4 + 2 * i]
      if left <= frontier and right > farthest: farthest = right
    if farthest == frontier: return -1
    frontier = farthest
    inc selected
  selected
