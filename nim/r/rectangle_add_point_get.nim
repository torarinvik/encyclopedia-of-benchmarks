const
  MaxN = 32
  MaxQ = 32
  MaxRectangles = MaxN + MaxQ
  MaxCoords = 2 * MaxRectangles
  MaxCorners = 4 * MaxRectangles
  MaxParseable = 2 + 5 * MaxN + 6 * MaxQ + 1
  MaxCoord = 1_000_000'i64
  MaxWeight = 1_000_000'i64

type
  Rectangle = object
    left, down, right, up, weight: int64
  Operation = object
    kind, a, b, c, d, e: int64

proc lowbit(value: int): int = value and -value

proc lowerBoundI64(values: openArray[int64], count: int, target: int64): int =
  var left = 0
  var right = count
  while left < right:
    let middle = left + (right - left) div 2
    if values[middle] < target: left = middle + 1
    else: right = middle
  left

proc upperBoundI64(values: openArray[int64], count: int, target: int64): int =
  var left = 0
  var right = count
  while left < right:
    let middle = left + (right - left) div 2
    if values[middle] <= target: left = middle + 1
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

proc sortUnique(values: var array[MaxCorners, int64], count: int): int =
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

proc registerEvent(xs, ys: array[MaxCorners, int64], xCount, yCount: int,
    present: var array[(MaxCoords + 1) * MaxCoords, bool], x, y: int64) =
  var outer = lowerBoundI64(xs, xCount, x) + 1
  let rank = lowerBoundI64(ys, yCount, y)
  while outer <= xCount:
    present[outer * MaxCoords + rank] = true
    outer += lowbit(outer)

proc registerRectangle(xs, ys: array[MaxCorners, int64], xCount, yCount: int,
    present: var array[(MaxCoords + 1) * MaxCoords, bool], rectangle: Rectangle) =
  registerEvent(xs, ys, xCount, yCount, present, rectangle.left, rectangle.down)
  registerEvent(xs, ys, xCount, yCount, present, rectangle.right, rectangle.down)
  registerEvent(xs, ys, xCount, yCount, present, rectangle.left, rectangle.up)
  registerEvent(xs, ys, xCount, yCount, present, rectangle.right, rectangle.up)

proc fenwickAdd(tree: var array[(MaxCoords + 1) * (MaxCoords + 1), int64],
    yValues: array[(MaxCoords + 1) * MaxCoords, int], yCounts: array[MaxCoords + 1, int],
    xs, ys: array[MaxCorners, int64], xCount, yCount: int,
    x, y, weight: int64) =
  var outer = lowerBoundI64(xs, xCount, x) + 1
  let yRank = lowerBoundI64(ys, yCount, y)
  while outer <= xCount:
    let row = outer * MaxCoords
    var inner = 0
    if yCounts[outer] > 0:
      inner = lowerBoundInt(yValues.toOpenArray(row, row + yCounts[outer] - 1),
                            yCounts[outer], yRank) + 1
    while inner > 0 and inner <= yCounts[outer]:
      tree[outer * (MaxCoords + 1) + inner] += weight
      inner += lowbit(inner)
    outer += lowbit(outer)

proc applyRectangle(tree: var array[(MaxCoords + 1) * (MaxCoords + 1), int64],
    yValues: array[(MaxCoords + 1) * MaxCoords, int], yCounts: array[MaxCoords + 1, int],
    xs, ys: array[MaxCorners, int64], xCount, yCount: int, rectangle: Rectangle) =
  fenwickAdd(tree, yValues, yCounts, xs, ys, xCount, yCount,
             rectangle.left, rectangle.down, rectangle.weight)
  fenwickAdd(tree, yValues, yCounts, xs, ys, xCount, yCount,
             rectangle.right, rectangle.down, -rectangle.weight)
  fenwickAdd(tree, yValues, yCounts, xs, ys, xCount, yCount,
             rectangle.left, rectangle.up, -rectangle.weight)
  fenwickAdd(tree, yValues, yCounts, xs, ys, xCount, yCount,
             rectangle.right, rectangle.up, rectangle.weight)

proc prefixSum(tree: array[(MaxCoords + 1) * (MaxCoords + 1), int64],
    yValues: array[(MaxCoords + 1) * MaxCoords, int], yCounts: array[MaxCoords + 1, int],
    xs, ys: array[MaxCorners, int64], xCount, yCount: int,
    xLimit, yLimit: int64): int64 =
  var outer = upperBoundI64(xs, xCount, xLimit)
  let yLimitRank = upperBoundI64(ys, yCount, yLimit)
  while outer > 0:
    let row = outer * MaxCoords
    var inner = 0
    if yCounts[outer] > 0:
      inner = lowerBoundInt(yValues.toOpenArray(row, row + yCounts[outer] - 1),
                            yCounts[outer], yLimitRank)
    while inner > 0:
      result += tree[outer * (MaxCoords + 1) + inner]
      inner -= lowbit(inner)
    outer -= lowbit(outer)

proc putI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc rectangle_add_point_get*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "rectangle_add_point_get".} =
  if input.isNil or length < 2 or length > csize_t(MaxParseable): return -1
  let nValue = input[0]
  let qValue = input[1]
  if nValue < 1 or nValue > MaxN or qValue < 1 or qValue > MaxQ: return -1
  let n = int(nValue)
  let q = int(qValue)
  var initial: array[MaxN, Rectangle]
  var operations: array[MaxQ, Operation]
  var allX, allY: array[MaxCorners, int64]
  var rectangleCount = 0
  var cursor = 2
  for index in 0 ..< n:
    if cursor + 5 > int(length): return -1
    let rectangle = Rectangle(left: input[cursor], down: input[cursor + 1],
      right: input[cursor + 2], up: input[cursor + 3], weight: input[cursor + 4])
    cursor += 5
    if rectangle.left < 0 or rectangle.left >= rectangle.right or rectangle.right > MaxCoord or
        rectangle.down < 0 or rectangle.down >= rectangle.up or rectangle.up > MaxCoord or
        rectangle.weight < 0 or rectangle.weight > MaxWeight: return -1
    initial[index] = rectangle
    allX[4 * rectangleCount] = rectangle.left
    allY[4 * rectangleCount] = rectangle.down
    allX[4 * rectangleCount + 1] = rectangle.right
    allY[4 * rectangleCount + 1] = rectangle.down
    allX[4 * rectangleCount + 2] = rectangle.left
    allY[4 * rectangleCount + 2] = rectangle.up
    allX[4 * rectangleCount + 3] = rectangle.right
    allY[4 * rectangleCount + 3] = rectangle.up
    inc rectangleCount
  for index in 0 ..< q:
    if cursor >= int(length): return -1
    let kind = input[cursor]
    inc cursor
    if kind == 0:
      if cursor + 5 > int(length): return -1
      let rectangle = Rectangle(left: input[cursor], down: input[cursor + 1],
        right: input[cursor + 2], up: input[cursor + 3], weight: input[cursor + 4])
      cursor += 5
      if rectangle.left < 0 or rectangle.left >= rectangle.right or rectangle.right > MaxCoord or
          rectangle.down < 0 or rectangle.down >= rectangle.up or rectangle.up > MaxCoord or
          rectangle.weight < 0 or rectangle.weight > MaxWeight: return -1
      operations[index] = Operation(kind: 0, a: rectangle.left, b: rectangle.down,
        c: rectangle.right, d: rectangle.up, e: rectangle.weight)
      allX[4 * rectangleCount] = rectangle.left
      allY[4 * rectangleCount] = rectangle.down
      allX[4 * rectangleCount + 1] = rectangle.right
      allY[4 * rectangleCount + 1] = rectangle.down
      allX[4 * rectangleCount + 2] = rectangle.left
      allY[4 * rectangleCount + 2] = rectangle.up
      allX[4 * rectangleCount + 3] = rectangle.right
      allY[4 * rectangleCount + 3] = rectangle.up
      inc rectangleCount
    elif kind == 1:
      if cursor + 2 > int(length): return -1
      let x = input[cursor]
      let y = input[cursor + 1]
      cursor += 2
      if x < 0 or x > MaxCoord or y < 0 or y > MaxCoord: return -1
      operations[index] = Operation(kind: 1, a: x, b: y)
    else: return -1
  if cursor != int(length): return -1

  let cornerCount = rectangleCount * 4
  let xCount = sortUnique(allX, cornerCount)
  let yCount = sortUnique(allY, cornerCount)
  var present: array[(MaxCoords + 1) * MaxCoords, bool]
  for rectangle in initial.toOpenArray(0, n - 1):
    registerRectangle(allX, allY, xCount, yCount, present,
      Rectangle(left: rectangle.left, down: rectangle.down, right: rectangle.right, up: rectangle.up, weight: 0))
  for index in 0 ..< q:
    let operation = operations[index]
    if operation.kind == 0:
      registerRectangle(allX, allY, xCount, yCount, present,
        Rectangle(left: operation.a, down: operation.b, right: operation.c, up: operation.d, weight: 0))
  var yValues: array[(MaxCoords + 1) * MaxCoords, int]
  var yCounts: array[MaxCoords + 1, int]
  for outer in 1 .. xCount:
    for rank in 0 ..< yCount:
      if present[outer * MaxCoords + rank]:
        yValues[outer * MaxCoords + yCounts[outer]] = rank
        inc yCounts[outer]
  var tree: array[(MaxCoords + 1) * (MaxCoords + 1), int64]
  for rectangle in initial.toOpenArray(0, n - 1):
    applyRectangle(tree, yValues, yCounts, allX, allY, xCount, yCount, rectangle)
  var answers: array[MaxQ, int64]
  var answerCount = 0
  for index in 0 ..< q:
    let operation = operations[index]
    if operation.kind == 0:
      applyRectangle(tree, yValues, yCounts, allX, allY, xCount, yCount,
        Rectangle(left: operation.a, down: operation.b, right: operation.c,
                  up: operation.d, weight: operation.e))
    else:
      answers[answerCount] = prefixSum(tree, yValues, yCounts, allX, allY, xCount, yCount,
                                        operation.a, operation.b)
      inc answerCount

  let outputBytes = 8 * answerCount
  if outputBytes > 0 and (output.isNil or capacity < csize_t(outputBytes)): return -2
  for index in 0 ..< answerCount: putI64Le(output, 8 * index, answers[index])
  int64(outputBytes)
