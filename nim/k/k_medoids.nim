const InvalidResult = -1'i64
const MaxPackedLength = 16

type I64Input = ptr UncheckedArray[int64]

proc distanceI64(a, b: int64): int64 =
  if a >= b: a - b else: b - a

proc k_medoids*(packed: I64Input, length: csize_t): int64 {.cdecl, exportc: "k_medoids".} =
  if packed == nil or length < 3 or length > csize_t(MaxPackedLength): return InvalidResult
  let pointCount = packed[0]
  let medoidCount = packed[1]
  let maxIter = packed[2]
  if pointCount < 2 or pointCount > 8 or medoidCount < 1 or medoidCount > 4 or medoidCount > pointCount or
      maxIter < 1 or maxIter > 16 or length != csize_t(3 + pointCount + medoidCount): return InvalidResult
  let n = int(pointCount)
  let k = int(medoidCount)
  var medoids: array[4, int64]
  var points: array[8, int64]
  var labels: array[8, int64]
  for slot in 0 ..< k:
    medoids[slot] = packed[3 + slot]
    if medoids[slot] < 0 or medoids[slot] >= pointCount: return InvalidResult
    for earlier in 0 ..< slot:
      if medoids[earlier] == medoids[slot]: return InvalidResult
  for i in 0 ..< n:
    points[i] = packed[3 + k + i]
    if points[i] < -16 or points[i] > 16: return InvalidResult
    for earlier in 0 ..< i:
      if points[earlier] == points[i]: return InvalidResult

  for _ in 0 ..< int(maxIter):
    for i in 0 ..< n:
      var bestSlot = 0
      var bestDistance = distanceI64(points[i], points[int(medoids[0])])
      for slot in 1 ..< k:
        let distance = distanceI64(points[i], points[int(medoids[slot])])
        if distance < bestDistance:
          bestDistance = distance
          bestSlot = slot
      labels[i] = int64(bestSlot)

    var updated: array[4, int64]
    for slot in 0 ..< k:
      var first = n
      for i in 0 ..< n:
        if labels[i] == int64(slot):
          first = i
          break
      if first == n: return InvalidResult
      var bestIndex = first
      var bestCost = 0'i64
      for i in 0 ..< n:
        if labels[i] == int64(slot): bestCost += distanceI64(points[first], points[i])
      for candidate in first + 1 ..< n:
        if labels[candidate] != int64(slot): continue
        var cost = 0'i64
        for i in 0 ..< n:
          if labels[i] == int64(slot): cost += distanceI64(points[candidate], points[i])
        if cost < bestCost:
          bestCost = cost
          bestIndex = candidate
      updated[slot] = int64(bestIndex)

    var changed = false
    for slot in 0 ..< k:
      if updated[slot] != medoids[slot]: changed = true
    if not changed: break
    medoids = updated

  var result = 0'i64
  for slot in 0 ..< k: result = result or (medoids[slot] shl (3 * slot))
  for i in 0 ..< n: result = result or (labels[i] shl (12 + 2 * i))
  result
