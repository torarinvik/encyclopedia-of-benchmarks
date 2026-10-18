const MaxCities = 8
const MaxParseableInputLength = 67
const MaxEdgeCost = 1_000'i64

proc nextPermutation(values: var array[7, int], length: int): bool =
  if length < 2: return false
  var pivot = length - 1
  while pivot > 0 and values[pivot - 1] >= values[pivot]:
    dec pivot
  if pivot == 0: return false
  dec pivot

  var successor = length - 1
  while values[successor] <= values[pivot]:
    dec successor
  swap(values[pivot], values[successor])

  var left = pivot + 1
  var right = length - 1
  while left < right:
    swap(values[left], values[right])
    inc left
    dec right
  true

proc traveling_salesman_solver_brute_force*(input: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "traveling_salesman_solver_brute_force".} =
  if input == nil or length < csize_t(2) or length > csize_t(MaxParseableInputLength):
    return -1.0e300
  let selector = input[0]
  let cityCountValue = input[1]
  if cityCountValue < 2 or cityCountValue > int64(MaxCities): return -1.0e300
  if selector < 0 or selector > cityCountValue + 1: return -1.0e300
  let cityCount = int(cityCountValue)
  if length != csize_t(2 + cityCount * cityCount): return -1.0e300

  var distances: array[64, int64]
  for index in 0 ..< cityCount * cityCount:
    let cost = input[index + 2]
    if cost < 0 or cost > MaxEdgeCost: return -1.0e300
    distances[index] = cost

  let permutationLength = cityCount - 1
  var permutation: array[7, int]
  for index in 0 ..< permutationLength:
    permutation[index] = index + 1

  var bestDistance = high(int64)
  var bestRoute: array[9, int]
  while true:
    var route: array[9, int]
    route[0] = 0
    for index in 0 ..< permutationLength:
      route[index + 1] = permutation[index]
    route[cityCount] = 0

    var distance = 0'i64
    for index in 0 ..< cityCount:
      distance += distances[route[index] * cityCount + route[index + 1]]
    if distance < bestDistance:
      bestDistance = distance
      for index in 0 .. cityCount:
        bestRoute[index] = route[index]

    if not nextPermutation(permutation, permutationLength): break

  if selector == 0: return float64(bestDistance)
  float64(bestRoute[int(selector - 1)])
