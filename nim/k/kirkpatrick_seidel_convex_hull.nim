const
  MaxPoints = 32
  MaxInputValues = 66
  MaxCoordinate = 1_000'i64

type
  Point = object
    x, y: int64
  Slope = object
    dy, dx: int64

proc compareSlope(a, b: Slope): int =
  let left = a.dy * b.dx
  let right = b.dy * a.dx
  if left < right: -1 elif left > right: 1 else: 0

proc sortIdsByX(ids: var seq[int], points: openArray[Point]) =
  for index in 1 ..< ids.len:
    let value = ids[index]
    var cursor = index
    while cursor > 0 and points[ids[cursor - 1]].x > points[value].x:
      ids[cursor] = ids[cursor - 1]
      dec cursor
    ids[cursor] = value

proc selectIdByX(ids: var seq[int], rank: int, points: openArray[Point]): int =
  if ids.len <= 5:
    sortIdsByX(ids, points)
    return ids[rank]
  var medians: seq[int] = @[]
  var start = 0
  while start < ids.len:
    let groupEnd = min(start + 5, ids.len)
    var group = ids[start ..< groupEnd]
    sortIdsByX(group, points)
    medians.add(group[(group.len - 1) div 2])
    start = groupEnd
  let pivot = selectIdByX(medians, (medians.len - 1) div 2, points)
  var lower: seq[int] = @[]
  var equal: seq[int] = @[]
  var upper: seq[int] = @[]
  for id in ids:
    if points[id].x < points[pivot].x: lower.add(id)
    elif points[id].x > points[pivot].x: upper.add(id)
    else: equal.add(id)
  if rank < lower.len: return selectIdByX(lower, rank, points)
  if rank < lower.len + equal.len: return pivot
  selectIdByX(upper, rank - lower.len - equal.len, points)

proc sortSlopes(values: var seq[Slope]) =
  for index in 1 ..< values.len:
    let value = values[index]
    var cursor = index
    while cursor > 0 and compareSlope(values[cursor - 1], value) > 0:
      values[cursor] = values[cursor - 1]
      dec cursor
    values[cursor] = value

proc selectSlope(values: var seq[Slope], rank: int): Slope =
  if values.len <= 5:
    sortSlopes(values)
    return values[rank]
  var medians: seq[Slope] = @[]
  var start = 0
  while start < values.len:
    let groupEnd = min(start + 5, values.len)
    var group = values[start ..< groupEnd]
    sortSlopes(group)
    medians.add(group[(group.len - 1) div 2])
    start = groupEnd
  let pivot = selectSlope(medians, (medians.len - 1) div 2)
  var lower: seq[Slope] = @[]
  var equal: seq[Slope] = @[]
  var upper: seq[Slope] = @[]
  for value in values:
    let order = compareSlope(value, pivot)
    if order < 0: lower.add(value)
    elif order > 0: upper.add(value)
    else: equal.add(value)
  if rank < lower.len: return selectSlope(lower, rank)
  if rank < lower.len + equal.len: return pivot
  selectSlope(upper, rank - lower.len - equal.len)

proc pairSlope(first, second: int, points: openArray[Point]): Slope =
  var left = first
  var right = second
  if points[left].x > points[right].x: swap(left, right)
  Slope(dy: points[right].y - points[left].y,
        dx: points[right].x - points[left].x)

proc upperBridge(points: openArray[Point], candidates: var seq[int],
                 separator: int64): tuple[left, right: int] =
  while candidates.len > 2:
    var slopes: seq[Slope] = @[]
    for index in countup(0, candidates.len - 2, 2):
      slopes.add(pairSlope(candidates[index], candidates[index + 1], points))
    let median = selectSlope(slopes, (slopes.len - 1) div 2)
    var support = low(int64)
    for id in candidates:
      support = max(support, points[id].y * median.dx - median.dy * points[id].x)
    var left = -1
    var right = -1
    for id in candidates:
      if points[id].y * median.dx - median.dy * points[id].x == support:
        if left < 0 or points[id].x < points[left].x: left = id
        if right < 0 or points[id].x > points[right].x: right = id
    if points[left].x <= separator and separator < points[right].x:
      return (left, right)

    let supportIsLeft = points[right].x <= separator
    var retained: seq[int] = @[]
    for index in countup(0, candidates.len - 2, 2):
      let first = candidates[index]
      let second = candidates[index + 1]
      let order = compareSlope(pairSlope(first, second, points), median)
      if supportIsLeft:
        if order < 0:
          retained.add(first)
          retained.add(second)
        else: retained.add(if points[first].x > points[second].x: first else: second)
      elif order > 0:
        retained.add(first)
        retained.add(second)
      else:
        retained.add(if points[first].x < points[second].x: first else: second)
    if candidates.len mod 2 == 1: retained.add(candidates[^1])
    candidates = retained
  if points[candidates[0]].x < points[candidates[1]].x:
    (candidates[0], candidates[1])
  else:
    (candidates[1], candidates[0])

proc appendUnique(chain: var seq[int], point: int) =
  if chain.len == 0 or chain[^1] != point: chain.add(point)

proc connectUpper(points: openArray[Point], candidates: seq[int], left, right: int,
                  chain: var seq[int]) =
  if left == right:
    appendUnique(chain, left)
    return
  var medianIds = newSeq[int](candidates.len)
  for index, id in candidates: medianIds[index] = id
  let separator = points[selectIdByX(medianIds, (medianIds.len - 1) div 2, points)].x
  var bridgeCandidates = newSeq[int](candidates.len)
  for index, id in candidates: bridgeCandidates[index] = id
  let bridge = upperBridge(points, bridgeCandidates, separator)
  var leftSet: seq[int] = @[]
  var rightSet: seq[int] = @[]
  for id in candidates:
    if points[id].x <= points[bridge.left].x: leftSet.add(id)
    if points[id].x >= points[bridge.right].x: rightSet.add(id)
  connectUpper(points, leftSet, left, bridge.left, chain)
  appendUnique(chain, bridge.right)
  connectUpper(points, rightSet, bridge.right, right, chain)

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255)

proc kirkpatrick_seidel_convex_hull*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "kirkpatrick_seidel_convex_hull".} =
  if values == nil or length < 1 or length > csize_t(MaxInputValues): return -1
  if values[0] < 3 or values[0] > MaxPoints: return -1
  let count = int(values[0])
  if length != csize_t(1 + 2 * count): return -1
  var original = newSeq[Point](count)
  var upperPoints = newSeq[Point](count)
  var lowerPoints = newSeq[Point](count)
  var seenX: array[2 * int(MaxCoordinate) + 1, bool]
  for index in 0 ..< count:
    let x = values[1 + 2 * index]
    let y = values[2 + 2 * index]
    if x < -MaxCoordinate or x > MaxCoordinate or y < -MaxCoordinate or y > MaxCoordinate: return -1
    let slot = int(x + MaxCoordinate)
    if seenX[slot]: return -1
    seenX[slot] = true
    original[index] = Point(x: x, y: y)
    upperPoints[index] = Point(x: x, y: y)
    lowerPoints[index] = Point(x: x, y: -y)
  var nonCollinear = false
  for index in 2 ..< count:
    let cross = (original[1].x - original[0].x) * (original[index].y - original[0].y) -
                (original[1].y - original[0].y) * (original[index].x - original[0].x)
    if cross != 0: nonCollinear = true
  if not nonCollinear: return -1
  var ids = newSeq[int](count)
  var leftIndex = 0
  var rightIndex = 0
  for index in 0 ..< count:
    ids[index] = index
    if original[index].x < original[leftIndex].x: leftIndex = index
    if original[index].x > original[rightIndex].x: rightIndex = index
  var upper: seq[int] = @[]
  var lower: seq[int] = @[]
  connectUpper(upperPoints, ids, leftIndex, rightIndex, upper)
  connectUpper(lowerPoints, ids, leftIndex, rightIndex, lower)
  var hull = lower
  if upper.len > 2:
    for index in countdown(upper.len - 2, 1): appendUnique(hull, upper[index])
  let byteCount = hull.len * 16
  if output == nil or outputCapacity < csize_t(byteCount): return -2
  for index, pointId in hull:
    storeI64Le(output, 16 * index, original[pointId].x)
    storeI64Le(output, 16 * index + 8, original[pointId].y)
  int64(byteCount)
