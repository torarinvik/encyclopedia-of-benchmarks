import std/math

const MaxCities = 8
const CoordinateLimit = 16.0

proc travelling_salesman_python_bruteforce*(input: ptr UncheckedArray[float64], inputLen: csize_t,
                                             output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "travelling_salesman_python_bruteforce".} =
  if input.isNil or inputLen < 3 or inputLen > 17: return -1
  let rawCount = input[0]
  if rawCount != rawCount or rawCount < 2.0 or rawCount > 8.0 or rawCount != floor(rawCount): return -1
  let cityCount = int(rawCount)
  if int(inputLen) != 1 + 2 * cityCount: return -1

  var x, y: array[MaxCities, float64]
  for city in 0..<cityCount:
    x[city] = input[1 + 2 * city]
    y[city] = input[2 + 2 * city]
    if x[city] != x[city] or y[city] != y[city] or
        x[city] < -CoordinateLimit or x[city] > CoordinateLimit or
        y[city] < -CoordinateLimit or y[city] > CoordinateLimit or
        x[city] != floor(x[city]) or y[city] != floor(y[city]): return -1

  let permutationLen = cityCount - 1
  var order, bestOrder: array[MaxCities - 1, int]
  for i in 0..<permutationLen: order[i] = i + 1
  var bestDistance = 1.0e300
  while true:
    var total = 0.0
    var previous = 0
    for i in 0..permutationLen:
      let next = if i == permutationLen: 0 else: order[i]
      let dx = x[next] - x[previous]
      let dy = y[next] - y[previous]
      total += sqrt(dx * dx + dy * dy)
      previous = next
    if total < bestDistance:
      bestDistance = total
      for i in 0..<permutationLen: bestOrder[i] = order[i]

    var i = permutationLen
    while i > 1 and order[i - 2] >= order[i - 1]: dec i
    if i <= 1: break
    let pivot = i - 2
    var j = permutationLen - 1
    while order[j] <= order[pivot]: dec j
    swap(order[pivot], order[j])
    var left = i - 1
    var right = permutationLen - 1
    while left < right:
      swap(order[left], order[right])
      inc left
      dec right

  var result: array[11, float64]
  let pathLen = cityCount + 1
  result[0] = float64(pathLen)
  result[1] = 0.0
  for i in 0..<permutationLen: result[2 + i] = float64(bestOrder[i])
  result[pathLen] = 0.0
  result[pathLen + 1] = bestDistance
  let required = cityCount + 3
  if output.isNil or outputCapacity < csize_t(required): return -2
  for i in 0..<required: output[i] = result[i]
  int64(required)
