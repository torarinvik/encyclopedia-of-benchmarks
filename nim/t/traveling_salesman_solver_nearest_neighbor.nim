const MaxCities = 8
const MaxParseableInputLength = 68
const MaxEdgeCost = 1_000'i64

proc traveling_salesman_solver_nearest_neighbor*(input: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "traveling_salesman_solver_nearest_neighbor".} =
  if input == nil or length < csize_t(3) or length > csize_t(MaxParseableInputLength):
    return -1.0e300
  let selector = input[0]
  let cityCountValue = input[1]
  let startValue = input[2]
  if cityCountValue < 1 or cityCountValue > int64(MaxCities): return -1.0e300
  if selector < 0 or selector > cityCountValue + 1: return -1.0e300
  if startValue < 0 or startValue >= cityCountValue: return -1.0e300
  let cityCount = int(cityCountValue)
  let start = int(startValue)
  if length != csize_t(3 + cityCount * cityCount): return -1.0e300

  var distances: array[64, int64]
  for index in 0 ..< cityCount * cityCount:
    let cost = input[index + 3]
    if cost < 0 or cost > MaxEdgeCost: return -1.0e300
    distances[index] = cost

  var visited: array[8, bool]
  var route: array[9, int]
  route[0] = start
  visited[start] = true
  var current = start
  var totalDistance = 0'i64

  for step in 1 ..< cityCount:
    var minimumDistance = high(int64)
    var nextCity = -1
    for city in 0 ..< cityCount:
      if not visited[city]:
        let cost = distances[current * cityCount + city]
        if cost < minimumDistance:
          minimumDistance = cost
          nextCity = city
    if nextCity < 0: return -1.0e300
    route[step] = nextCity
    visited[nextCity] = true
    totalDistance += minimumDistance
    current = nextCity

  totalDistance += distances[current * cityCount + start]
  route[cityCount] = start
  if selector == 0: return float64(totalDistance)
  float64(route[int(selector - 1)])
