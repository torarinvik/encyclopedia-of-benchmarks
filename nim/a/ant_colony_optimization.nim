import math

const AntLimit = 64
const IterationLimit = 64
const InvalidResult = -1.0e300

proc cityDistance(cities: array[6, int64], first, second: int): float64 =
  let dx = float64(cities[2 * first] - cities[2 * second])
  let dy = float64(cities[2 * first + 1] - cities[2 * second + 1])
  sqrt(dx * dx + dy * dy)

proc nextRandomFraction(state: var int64): float64 =
  state = (state * 48271) mod 2147483647
  float64(state) / 2147483647.0

proc selectNextCity(current: int, visited: array[3, bool], cities: array[6, int64],
                    pheromones: array[9, float64], state: var int64): int =
  var scores: array[3, float64]
  var total = 0.0
  for city in 0 ..< 3:
    if visited[city]: continue
    let heuristic = 1.0 / cityDistance(cities, current, city)
    let squared = heuristic * heuristic
    let fifth = squared * squared * heuristic
    scores[city] = pheromones[3 * current + city] * fifth
    total += scores[city]
  let roll = nextRandomFraction(state) * total
  var cumulative = 0.0
  var fallback = 0
  for city in 0 ..< 3:
    if visited[city]: continue
    fallback = city
    cumulative += scores[city]
    if cumulative >= roll: return city
  fallback

proc ant_colony_optimization*(input: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "ant_colony_optimization".} =
  if input == nil or length != 8: return InvalidResult
  if input[0] < 1 or input[0] > AntLimit or input[1] < 1 or input[1] > IterationLimit: return InvalidResult
  var cities: array[6, int64]
  for index in 0 ..< 6:
    cities[index] = input[index + 2]
    if cities[index] < -100_000 or cities[index] > 100_000: return InvalidResult
  for first in 0 ..< 3:
    for second in 0 ..< first:
      if cities[2 * first] == cities[2 * second] and cities[2 * first + 1] == cities[2 * second + 1]:
        return InvalidResult

  let antCount = int(input[0])
  let iterationCount = int(input[1])
  var pheromones: array[9, float64]
  for index in 0 ..< 9: pheromones[index] = 1.0
  var routes: array[AntLimit * 4, int]
  var randomState = 1'i64
  var bestDistance = Inf

  for _ in 0 ..< iterationCount:
    for ant in 0 ..< antCount:
      let routeStart = ant * 4
      routes[routeStart] = 0
      var current = 0
      var visited = [true, false, false]
      for step in 1 ..< 3:
        current = selectNextCity(current, visited, cities, pheromones, randomState)
        routes[routeStart + step] = current
        visited[current] = true
      routes[routeStart + 3] = 0
      var distance = 0.0
      for edge in 0 ..< 3:
        distance += cityDistance(cities, routes[routeStart + edge], routes[routeStart + edge + 1])
      if distance < bestDistance: bestDistance = distance
    for index in 0 ..< 9: pheromones[index] *= 0.7
    for ant in 0 ..< antCount:
      let routeStart = ant * 4
      var distance = 0.0
      for edge in 0 ..< 3:
        distance += cityDistance(cities, routes[routeStart + edge], routes[routeStart + edge + 1])
      let deposit = 10.0 / distance
      for edge in 0 ..< 3:
        let originCity = routes[routeStart + edge]
        let nextCity = routes[routeStart + edge + 1]
        pheromones[3 * originCity + nextCity] += deposit
        pheromones[3 * nextCity + originCity] += deposit
  bestDistance
