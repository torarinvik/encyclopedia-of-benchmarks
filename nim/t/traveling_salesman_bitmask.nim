const MaxCities = 10
const MaxMasks = 1024
const MaxStates = MaxCities * MaxMasks
const MaxInputValues = 102
const MaxDistance = 1_000'i64

proc solve(position, mask, cityCount: int,
           distances: var array[MaxCities * MaxCities, int64],
           memo: var array[MaxStates, int64],
           seen: var array[MaxStates, bool]): int64 =
  let allVisited = (1 shl cityCount) - 1
  if mask == allVisited: return distances[position * cityCount]
  let state = position * MaxMasks + mask
  if seen[state]: return memo[state]

  seen[state] = true
  var best = 10_001'i64
  for city in 0 ..< cityCount:
    let bit = 1 shl city
    if (mask and bit) == 0:
      let cost = distances[position * cityCount + city] +
        solve(city, mask or bit, cityCount, distances, memo, seen)
      if cost < best: best = cost
  memo[state] = best
  best

proc traveling_salesman_bitmask*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "traveling_salesman_bitmask".} =
  if input == nil or length < 1 or length > csize_t(MaxInputValues): return -1
  let cityCountValue = input[0]
  if cityCountValue < 2 or cityCountValue > MaxCities.int64: return -1
  let cityCount = int(cityCountValue)
  if length != csize_t(1 + cityCount * cityCount): return -1

  var distances: array[MaxCities * MaxCities, int64]
  for index in 0 ..< cityCount * cityCount:
    let distance = input[1 + index]
    if distance < 0 or distance > MaxDistance: return -1
    if index div cityCount == index mod cityCount and distance != 0: return -1
    distances[index] = distance

  var memo: array[MaxStates, int64]
  var seen: array[MaxStates, bool]
  solve(0, 1, cityCount, distances, memo, seen)
