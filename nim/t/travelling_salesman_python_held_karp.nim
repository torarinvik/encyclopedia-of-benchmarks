import math

const MaxCities = 8
const MaxInputValues = 17
const MaxOutputValues = 11
const MaxMasks = 256
const InfCost = 1e300

proc travelling_salesman_dynamic_programming*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64
    {.cdecl, exportc: "travelling_salesman_dynamic_programming".} =
  if input == nil or inputLength < 5 or inputLength > MaxInputValues.csize_t: return -1
  let nValue = input[0]
  if classify(nValue) in {fcNan, fcInf, fcNegInf} or nValue < 2.0 or nValue > float64(MaxCities) or floor(nValue) != nValue: return -1
  let n = int(nValue)
  if inputLength != csize_t(1 + 2 * n): return -1

  var x, y: array[MaxCities, float64]
  for city in 0 ..< n:
    let cx = input[1 + 2 * city]
    let cy = input[2 + 2 * city]
    if classify(cx) in {fcNan, fcInf, fcNegInf} or classify(cy) in {fcNan, fcInf, fcNegInf} or
        cx < -16.0 or cx > 16.0 or cy < -16.0 or cy > 16.0 or floor(cx) != cx or floor(cy) != cy: return -1
    x[city] = cx
    y[city] = cy

  var distances: array[MaxCities * MaxCities, float64]
  for from in 0 ..< n:
    for to in 0 ..< n:
      let dx = x[to] - x[from]
      let dy = y[to] - y[from]
      distances[from * MaxCities + to] = sqrt(dx * dx + dy * dy)

  var dp: array[MaxMasks * MaxCities, float64]
  for state in 0 ..< MaxMasks * MaxCities: dp[state] = InfCost
  dp[MaxCities] = 0.0
  let maskCount = 1 shl n
  for mask in 0 ..< maskCount:
    for u in 0 ..< n:
      if (mask and (1 shl u)) == 0: continue
      let prefix = dp[mask * MaxCities + u]
      for v in 0 ..< n:
        let bit = 1 shl v
        if (mask and bit) != 0: continue
        let nextMask = mask or bit
        let candidate = prefix + distances[u * MaxCities + v]
        if candidate < dp[nextMask * MaxCities + v]: dp[nextMask * MaxCities + v] = candidate

  let finalMask = maskCount - 1
  var minimum = InfCost
  var endNode = n
  for u in 1 ..< n:
    let candidate = dp[finalMask * MaxCities + u] + distances[u * MaxCities]
    if minimum > candidate:
      minimum = candidate
      endNode = u
  if endNode == n: return -1

  var reversePath: array[MaxCities + 1, int]
  var pathLength = 0
  var mask = finalMask
  while endNode != 0:
    reversePath[pathLength] = endNode
    inc pathLength
    let previousMask = mask xor (1 shl endNode)
    var found = false
    for u in 0 ..< n:
      if (mask and (1 shl u)) == 0: continue
      if dp[mask * MaxCities + endNode] == dp[previousMask * MaxCities + u] + distances[u * MaxCities + endNode]:
        mask = previousMask
        endNode = u
        found = true
        break
    if not found or pathLength > MaxCities: return -1
  reversePath[pathLength] = 0
  inc pathLength
  var left = 0
  var right = pathLength - 1
  while left < right:
    swap(reversePath[left], reversePath[right])
    inc left
    dec right
  reversePath[pathLength] = 0
  inc pathLength

  var staged: array[MaxOutputValues, float64]
  staged[0] = float64(pathLength)
  for index in 0 ..< pathLength: staged[index + 1] = float64(reversePath[index])
  staged[pathLength + 1] = minimum
  let outputSize = pathLength + 2
  if output == nil or capacity < csize_t(outputSize): return -2
  for index in 0 ..< outputSize: output[index] = staged[index]
  int64(outputSize)
