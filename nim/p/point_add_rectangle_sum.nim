const
  MaxN = 32
  MaxQ = 32
  MaxPoints = MaxN + MaxQ
  MaxParseable = 2 + 3 * MaxN + 5 * MaxQ + 1
  MaxCoord = 1_000_000'i64
  MaxWeight = 1_000_000'i64

type
  Point = object
    x, y, weight: int64
  Operation = object
    kind, a, b, c, d: int64

proc lowbit(value: int): int = value and -value

proc lowerBoundI64(values: openArray[int64], count: int, target: int64): int =
  var left = 0
  var right = count
  while left < right:
    let middle = left + (right - left) div 2
    if values[middle] < target: left = middle + 1
    else: right = middle
  left

proc lowerBoundInt(values: openArray[int], count, target: int): int =
  var left = 0
  var right = count
  while left < right:
    let middle = left + (right - left) div 2
    if values[middle] < target: left = middle + 1
    else: right = middle
  left

proc sortUnique(values: var array[MaxPoints, int64], count: int): int =
  for index in 1 ..< count:
    let value = values[index]
    var position = index
    while position > 0 and values[position - 1] > value:
      values[position] = values[position - 1]
      dec position
    values[position] = value
  var uniqueCount = 0
  for index in 0 ..< count:
    if uniqueCount == 0 or values[index] != values[uniqueCount - 1]:
      values[uniqueCount] = values[index]
      inc uniqueCount
  uniqueCount

proc registerCoordinate(xs, ys: array[MaxPoints, int64], xCount, yCount: int,
    present: var array[(MaxPoints + 1) * MaxPoints, bool], x, y: int64) =
  var outer = lowerBoundI64(xs, xCount, x) + 1
  let rank = lowerBoundI64(ys, yCount, y)
  while outer <= xCount:
    present[outer * MaxPoints + rank] = true
    outer += lowbit(outer)

proc fenwickAdd(tree: var array[(MaxPoints + 1) * (MaxPoints + 1), int64],
    yValues: array[(MaxPoints + 1) * MaxPoints, int], yCounts: array[MaxPoints + 1, int],
    xCount: int, xs, ys: array[MaxPoints, int64], yCount: int,
    x, y, weight: int64) =
  var outer = lowerBoundI64(xs, xCount, x) + 1
  let yRank = lowerBoundI64(ys, yCount, y)
  while outer <= xCount:
    let row = outer * MaxPoints
    var inner = lowerBoundInt(yValues.toOpenArray(row, row + yCounts[outer] - 1), yCounts[outer], yRank) + 1
    while inner <= yCounts[outer]:
      tree[outer * (MaxPoints + 1) + inner] += weight
      inner += lowbit(inner)
    outer += lowbit(outer)

proc prefixSum(tree: array[(MaxPoints + 1) * (MaxPoints + 1), int64],
    yValues: array[(MaxPoints + 1) * MaxPoints, int], yCounts: array[MaxPoints + 1, int],
    xCount: int, xs, ys: array[MaxPoints, int64], yCount: int,
    xLimit, yLimit: int64): int64 =
  var outer = lowerBoundI64(xs, xCount, xLimit)
  let yLimitRank = lowerBoundI64(ys, yCount, yLimit)
  while outer > 0:
    let row = outer * MaxPoints
    if yCounts[outer] > 0:
      var inner = lowerBoundInt(yValues.toOpenArray(row, row + yCounts[outer] - 1), yCounts[outer], yLimitRank)
      while inner > 0:
        result += tree[outer * (MaxPoints + 1) + inner]
        inner -= lowbit(inner)
    outer -= lowbit(outer)

proc putI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc point_add_rectangle_sum*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "point_add_rectangle_sum".} =
  if input.isNil or length < 2 or length > csize_t(MaxParseable): return -1
  let nValue = input[0]
  let qValue = input[1]
  if nValue < 1 or nValue > MaxN or qValue < 0 or qValue > MaxQ: return -1
  let n = int(nValue)
  let q = int(qValue)
  var initial: array[MaxN, Point]
  var operations: array[MaxQ, Operation]
  var allX, allY: array[MaxPoints, int64]
  var pointCount = 0
  var cursor = 2
  for index in 0 ..< n:
    if cursor + 3 > int(length): return -1
    let x = input[cursor]
    let y = input[cursor + 1]
    let weight = input[cursor + 2]
    cursor += 3
    if x < 0 or x > MaxCoord or y < 0 or y > MaxCoord or weight < 0 or weight > MaxWeight: return -1
    initial[index] = Point(x: x, y: y, weight: weight)
    allX[pointCount] = x
    allY[pointCount] = y
    inc pointCount
  var queryCount = 0
  for index in 0 ..< q:
    if cursor >= int(length): return -1
    let kind = input[cursor]
    inc cursor
    if kind == 0:
      if cursor + 3 > int(length): return -1
      let x = input[cursor]
      let y = input[cursor + 1]
      let weight = input[cursor + 2]
      cursor += 3
      if x < 0 or x > MaxCoord or y < 0 or y > MaxCoord or weight < 0 or weight > MaxWeight: return -1
      operations[index] = Operation(kind: 0, a: x, b: y, c: weight, d: 0)
      allX[pointCount] = x
      allY[pointCount] = y
      inc pointCount
    elif kind == 1:
      if cursor + 4 > int(length): return -1
      let left = input[cursor]
      let down = input[cursor + 1]
      let right = input[cursor + 2]
      let up = input[cursor + 3]
      cursor += 4
      if left < 0 or left >= right or right > MaxCoord or down < 0 or down >= up or up > MaxCoord: return -1
      operations[index] = Operation(kind: 1, a: left, b: down, c: right, d: up)
      inc queryCount
    else: return -1
  if cursor != int(length): return -1

  let xCount = sortUnique(allX, pointCount)
  let yCount = sortUnique(allY, pointCount)
  var present: array[(MaxPoints + 1) * MaxPoints, bool]
  for point in initial.toOpenArray(0, n - 1):
    registerCoordinate(allX, allY, xCount, yCount, present, point.x, point.y)
  for index in 0 ..< q:
    let op = operations[index]
    if op.kind == 0: registerCoordinate(allX, allY, xCount, yCount, present, op.a, op.b)

  var yValues: array[(MaxPoints + 1) * MaxPoints, int]
  var yCounts: array[MaxPoints + 1, int]
  for outer in 1 .. xCount:
    for rank in 0 ..< yCount:
      if present[outer * MaxPoints + rank]:
        yValues[outer * MaxPoints + yCounts[outer]] = rank
        inc yCounts[outer]
  var tree: array[(MaxPoints + 1) * (MaxPoints + 1), int64]
  for point in initial.toOpenArray(0, n - 1):
    fenwickAdd(tree, yValues, yCounts, xCount, allX, allY, yCount, point.x, point.y, point.weight)
  var answers: array[MaxQ, int64]
  var answerCount = 0
  for index in 0 ..< q:
    let op = operations[index]
    if op.kind == 0:
      fenwickAdd(tree, yValues, yCounts, xCount, allX, allY, yCount, op.a, op.b, op.c)
    else:
      answers[answerCount] = prefixSum(tree, yValues, yCounts, xCount, allX, allY, yCount, op.c, op.d) -
        prefixSum(tree, yValues, yCounts, xCount, allX, allY, yCount, op.a, op.d) -
        prefixSum(tree, yValues, yCounts, xCount, allX, allY, yCount, op.c, op.b) +
        prefixSum(tree, yValues, yCounts, xCount, allX, allY, yCount, op.a, op.b)
      inc answerCount

  let outputBytes = 8 * answerCount
  if outputBytes > 0 and (output.isNil or capacity < csize_t(outputBytes)): return -2
  for index in 0 ..< answerCount: putI64Le(output, 8 * index, answers[index])
  int64(outputBytes)
