const MinCities = 0
const MaxCities = 8
const MaxParseableInputLength = 66
const MaxEdgeCost = 1_000'i64
const JavaIntMin = -2_147_483_648'i64
const JavaIntMax = 2_147_483_647'i64

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

proc traveling_salesman*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "traveling_salesman".} =
  if input == nil or length < 1 or length > csize_t(MaxParseableInputLength):
    return -1

  let cityCountValue = input[0]
  if cityCountValue < MinCities.int64 or cityCountValue > MaxCities.int64: return -1
  let cityCount = int(cityCountValue)
  if length != csize_t(1 + cityCount * cityCount): return -1

  var distances: array[64, int64]
  for index in 0 ..< cityCount * cityCount:
    let distance = input[index + 1]
    if distance < JavaIntMin or distance > JavaIntMax: return -1
    if cityCount > 1 and index div cityCount != index mod cityCount and
        distance != JavaIntMax and (distance < 0 or distance > MaxEdgeCost):
      return -1
    distances[index] = distance

  if cityCount <= 1: return 0

  let permutationLength = cityCount - 1
  var permutation: array[7, int]
  for index in 0 ..< permutationLength:
    permutation[index] = index + 1

  var best = JavaIntMax
  while true:
    var routeCost = 0'i64
    var previous = 0
    var routeValid = true
    for index in 0 ..< permutationLength:
      let city = permutation[index]
      let edge = distances[previous * cityCount + city]
      if edge == JavaIntMax:
        routeValid = false
        break
      routeCost += edge
      previous = city

    if routeValid:
      let returnEdge = distances[previous * cityCount]
      if returnEdge != JavaIntMax:
        routeCost += returnEdge
        if routeCost < best: best = routeCost

    if not nextPermutation(permutation, permutationLength): break
  best
