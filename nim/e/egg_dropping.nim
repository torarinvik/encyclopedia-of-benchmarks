const MaxEggs = 12
const MaxFloors = 128
const FloorWidth = MaxFloors + 1
const InvalidResult = low(int64)

proc egg_dropping*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "egg_dropping".} =
  if input.isNil or length != 2: return InvalidResult
  if input[0] < 1 or input[0] > int64(MaxEggs) or input[1] < 1 or input[1] > int64(MaxFloors):
    return InvalidResult

  let eggs = int(input[0])
  let floors = int(input[1])
  var dp: array[(MaxEggs + 1) * FloorWidth, int64]

  for egg in 1 .. eggs: dp[egg * FloorWidth + 1] = 1
  for floor in 1 .. floors: dp[FloorWidth + floor] = int64(floor)
  for egg in 2 .. eggs:
    for floor in 2 .. floors:
      var best = high(int64)
      for drop in 1 .. floor:
        let breaks = dp[(egg - 1) * FloorWidth + drop - 1]
        let survives = dp[egg * FloorWidth + floor - drop]
        let worst = 1 + max(breaks, survives)
        if worst < best: best = worst
      dp[egg * FloorWidth + floor] = best
  dp[eggs * FloorWidth + floors]
