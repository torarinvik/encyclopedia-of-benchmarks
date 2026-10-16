const MaxEggs = 8
const MaxFloors = 32

proc egg_dropping_puzzle*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "egg_dropping_puzzle".} =
  if input == nil or length != 2: return -1
  let eggsValue = input[0]
  let floorsValue = input[1]
  if eggsValue < 1 or eggsValue > MaxEggs or floorsValue < 1 or floorsValue > MaxFloors: return -1

  let eggs = int(eggsValue)
  let floors = int(floorsValue)
  var dp: array[MaxEggs + 1, array[MaxFloors + 1, int64]]
  for egg in 1 .. eggs: dp[egg][1] = 1
  for floorCount in 1 .. floors: dp[1][floorCount] = int64(floorCount)

  for egg in 2 .. eggs:
    for floorCount in 2 .. floors:
      var best = int64(MaxFloors + 1)
      for dropFloor in 1 .. floorCount:
        let broken = dp[egg - 1][dropFloor - 1]
        let survives = dp[egg][floorCount - dropFloor]
        let worst = if broken > survives: broken else: survives
        let candidate = worst + 1
        if candidate < best: best = candidate
      dp[egg][floorCount] = best
  dp[eggs][floors]
