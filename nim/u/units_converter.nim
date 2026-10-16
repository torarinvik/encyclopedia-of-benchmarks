const MaxUnits = 8
const MaxConversions = MaxUnits * MaxUnits
const MaxValueMicro = 1_000_000_000_000'i64
const MaxSlopePpm = 5_000_000'i64
const MaxInterceptMicro = 1_000_000_000_000'i64
const InvalidResult = -1.0e300

proc findRoot(parent: var array[MaxUnits, int64], node: int64): int64 =
  var current = node
  while parent[current] != current:
    parent[current] = parent[parent[current]]
    current = parent[current]
  current

proc putIfNeeded(present: var array[MaxConversions, int64],
                 slopes: var array[MaxConversions, float64],
                 intercepts: var array[MaxConversions, float64], count: var int,
                 source, target: int, slope, intercept: float64): bool =
  if source == target: return false
  let slot = source * MaxUnits + target
  if present[slot] != 0: return false
  present[slot] = 1
  slopes[slot] = slope
  intercepts[slot] = intercept
  inc count
  true

proc addAll(knownPresent: array[MaxConversions, int64],
            knownSlopes: array[MaxConversions, float64],
            knownIntercepts: array[MaxConversions, float64], unitCount: int,
            resultPresent: var array[MaxConversions, int64],
            resultSlopes: var array[MaxConversions, float64],
            resultIntercepts: var array[MaxConversions, float64]): int =
  var inversePresent: array[MaxConversions, int64]
  var inverseSlopes: array[MaxConversions, float64]
  var inverseIntercepts: array[MaxConversions, float64]
  var inverseCount = 0
  for source in 0 ..< unitCount:
    for target in 0 ..< unitCount:
      let slot = source * MaxUnits + target
      if knownPresent[slot] == 0: continue
      discard putIfNeeded(inversePresent, inverseSlopes, inverseIntercepts, inverseCount,
                          source, target, knownSlopes[slot], knownIntercepts[slot])
      discard putIfNeeded(inversePresent, inverseSlopes, inverseIntercepts, inverseCount,
                          target, source, 1.0 / knownSlopes[slot],
                          -knownIntercepts[slot] / knownSlopes[slot])

  var resultCount = 0
  for firstSource in 0 ..< unitCount:
    for middle in 0 ..< unitCount:
      let firstSlot = firstSource * MaxUnits + middle
      if inversePresent[firstSlot] == 0: continue
      discard putIfNeeded(resultPresent, resultSlopes, resultIntercepts, resultCount,
                          firstSource, middle, inverseSlopes[firstSlot], inverseIntercepts[firstSlot])
      for target in 0 ..< unitCount:
        let secondSlot = middle * MaxUnits + target
        if inversePresent[secondSlot] == 0: continue
        discard putIfNeeded(resultPresent, resultSlopes, resultIntercepts, resultCount,
                            firstSource, target,
                            inverseSlopes[secondSlot] * inverseSlopes[firstSlot],
                            inverseSlopes[secondSlot] * inverseIntercepts[firstSlot] +
                                inverseIntercepts[secondSlot])
  resultCount

proc units_converter*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "units_converter".} =
  if values == nil or length < 4 or length > 35: return InvalidResult
  var sourceValue, targetValue, valueMicro: int64
  var unitCount: int
  var knownPresent: array[MaxConversions, int64]
  var knownSlopes: array[MaxConversions, float64]
  var knownIntercepts: array[MaxConversions, float64]
  var knownCount = 0

  if values[0] == 0:
    if length != 4: return InvalidResult
    sourceValue = values[1]
    targetValue = values[2]
    valueMicro = values[3]
    unitCount = 6
    let sourceUnits = [0, 1, 3, 4, 5]
    let targetUnits = [1, 2, 1, 1, 0]
    let slopes = [1.0, 9.0 / 5.0, 5.0 / 4.0, -2.0 / 3.0, 5.0 / 9.0]
    let intercepts = [-273.15, 32.0, 0.0, 100.0, 0.0]
    for edge in 0 ..< 5:
      let slot = sourceUnits[edge] * MaxUnits + targetUnits[edge]
      knownPresent[slot] = 1
      knownSlopes[slot] = slopes[edge]
      knownIntercepts[slot] = intercepts[edge]
      inc knownCount
  elif values[0] == 1:
    if length < 6: return InvalidResult
    let unitCountValue = values[1]
    let edgeCount = values[2]
    sourceValue = values[3]
    targetValue = values[4]
    valueMicro = values[5]
    if unitCountValue < 2 or unitCountValue > MaxUnits or edgeCount < 0 or
        edgeCount > unitCountValue - 1 or length != csize_t(6 + 4 * edgeCount):
      return InvalidResult
    unitCount = int(unitCountValue)
    var parent: array[MaxUnits, int64]
    for unit in 0 ..< unitCount: parent[unit] = int64(unit)
    for edge in 0 ..< int(edgeCount):
      let offset = 6 + 4 * edge
      let fromValue = values[offset]
      let toValue = values[offset + 1]
      let slopePpm = values[offset + 2]
      let interceptMicro = values[offset + 3]
      if fromValue < 0 or fromValue >= unitCountValue or toValue < 0 or toValue >= unitCountValue or
          fromValue == toValue or slopePpm == 0 or slopePpm < -MaxSlopePpm or slopePpm > MaxSlopePpm or
          interceptMicro < -MaxInterceptMicro or interceptMicro > MaxInterceptMicro:
        return InvalidResult
      let rootFrom = findRoot(parent, fromValue)
      let rootTo = findRoot(parent, toValue)
      if rootFrom == rootTo: return InvalidResult
      parent[rootFrom] = rootTo
      let slot = int(fromValue) * MaxUnits + int(toValue)
      knownPresent[slot] = 1
      knownSlopes[slot] = float64(slopePpm) / 1_000_000.0
      knownIntercepts[slot] = float64(interceptMicro) / 1_000_000.0
      inc knownCount
  else:
    return InvalidResult

  if sourceValue < 0 or sourceValue >= int64(unitCount) or targetValue < 0 or
      targetValue >= int64(unitCount) or sourceValue == targetValue or
      valueMicro < -MaxValueMicro or valueMicro > MaxValueMicro:
    return InvalidResult

  var stable = false
  for iteration in 0 .. MaxUnits:
    var nextPresent: array[MaxConversions, int64]
    var nextSlopes: array[MaxConversions, float64]
    var nextIntercepts: array[MaxConversions, float64]
    let nextCount = addAll(knownPresent, knownSlopes, knownIntercepts, unitCount,
                           nextPresent, nextSlopes, nextIntercepts)
    knownPresent = nextPresent
    knownSlopes = nextSlopes
    knownIntercepts = nextIntercepts
    if nextCount == knownCount:
      stable = true
      break
    knownCount = nextCount
  if not stable: return InvalidResult

  let resultSlot = int(sourceValue) * MaxUnits + int(targetValue)
  if knownPresent[resultSlot] == 0: return InvalidResult
  let value = float64(valueMicro) / 1_000_000.0
  knownSlopes[resultSlot] * value + knownIntercepts[resultSlot]
