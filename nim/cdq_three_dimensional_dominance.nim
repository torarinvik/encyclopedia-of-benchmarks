const
  MaxN = 64
  MaxParseableLength = 194

type
  Point = object
    x, y, z, multiplicity: int64
    zRank, originalIndex: int
  Workspace = object
    points: array[MaxN, Point]
    originalGroup: array[MaxN, int]
    dominated: array[MaxN, int64]
    bit: array[MaxN + 1, int64]
    sourceOrder, targetOrder: array[MaxN, int]
    zValues: array[MaxN, int64]

proc pointLess(a, b: Point): bool =
  if a.x != b.x: return a.x < b.x
  if a.y != b.y: return a.y < b.y
  a.z < b.z

proc sameCoordinates(a, b: Point): bool =
  a.x == b.x and a.y == b.y and a.z == b.z

proc bitAdd(work: var Workspace, start: int, delta: int64, limit: int) =
  var index = start
  while index <= limit:
    work.bit[index] += delta
    index += index and -index

proc bitSum(work: Workspace, start: int): int64 =
  var index = start
  while index > 0:
    result += work.bit[index]
    index -= index and -index

proc cdq(work: var Workspace, left, right, groupCount: int) =
  if left >= right: return
  let middle = left + (right - left) div 2
  cdq(work, left, middle, groupCount)
  cdq(work, middle + 1, right, groupCount)

  var inserted = 0
  for targetPosition in middle + 1 .. right:
    let target = work.sourceOrder[targetPosition]
    while inserted + left <= middle:
      let source = work.sourceOrder[left + inserted]
      if work.points[source].y > work.points[target].y: break
      let sourceRank = work.points[source].zRank
      let sourceWeight = work.points[source].multiplicity
      bitAdd(work, sourceRank, sourceWeight, groupCount)
      inc inserted
    let targetRank = work.points[target].zRank
    let amount = bitSum(work, targetRank)
    work.dominated[target] += amount
  for offset in 0 ..< inserted:
    let source = work.sourceOrder[left + offset]
    let sourceRank = work.points[source].zRank
    let sourceWeight = work.points[source].multiplicity
    bitAdd(work, sourceRank, -sourceWeight, groupCount)

  var leftCursor = left
  var rightCursor = middle + 1
  var destination = left
  while leftCursor <= middle and rightCursor <= right:
    let leftPoint = work.sourceOrder[leftCursor]
    let rightPoint = work.sourceOrder[rightCursor]
    if work.points[leftPoint].y <= work.points[rightPoint].y:
      work.targetOrder[destination] = leftPoint
      inc leftCursor
    else:
      work.targetOrder[destination] = rightPoint
      inc rightCursor
    inc destination
  while leftCursor <= middle:
    work.targetOrder[destination] = work.sourceOrder[leftCursor]
    inc leftCursor
    inc destination
  while rightCursor <= right:
    work.targetOrder[destination] = work.sourceOrder[rightCursor]
    inc rightCursor
    inc destination
  for i in left .. right: work.sourceOrder[i] = work.targetOrder[i]

proc solve(input: ptr UncheckedArray[int64], length: int): int64 =
  if input.isNil or length < 1 or length > MaxParseableLength: return -1
  if input[0] < 1 or input[0] > int64(MaxN): return -1
  let n = int(input[0])
  if length != 1 + 3 * n: return -1

  var work: Workspace
  for i in 0 ..< n:
    let x = input[1 + 3 * i]
    let y = input[2 + 3 * i]
    let z = input[3 + 3 * i]
    if x < -1000 or x > 1000 or y < -1000 or y > 1000 or z < -1000 or z > 1000: return -1
    work.points[i] = Point(x: x, y: y, z: z, multiplicity: 1, zRank: 0, originalIndex: i)

  for i in 1 ..< n:
    let value = work.points[i]
    var j = i
    while j > 0 and pointLess(value, work.points[j - 1]):
      work.points[j] = work.points[j - 1]
      dec j
    work.points[j] = value

  var groupCount = 0
  for i in 0 ..< n:
    let point = work.points[i]
    if groupCount > 0 and sameCoordinates(point, work.points[groupCount - 1]):
      inc work.points[groupCount - 1].multiplicity
      work.originalGroup[point.originalIndex] = groupCount - 1
    else:
      work.points[groupCount] = point
      work.points[groupCount].multiplicity = 1
      work.originalGroup[point.originalIndex] = groupCount
      inc groupCount

  for i in 0 ..< groupCount: work.zValues[i] = work.points[i].z
  for i in 1 ..< groupCount:
    let value = work.zValues[i]
    var j = i
    while j > 0 and value < work.zValues[j - 1]:
      work.zValues[j] = work.zValues[j - 1]
      dec j
    work.zValues[j] = value
  var zCount = 0
  for i in 0 ..< groupCount:
    let value = work.zValues[i]
    if zCount == 0 or value != work.zValues[zCount - 1]:
      work.zValues[zCount] = value
      inc zCount
  for i in 0 ..< groupCount:
    var low = 0
    var high = zCount
    while low < high:
      let middle = low + (high - low) div 2
      if work.zValues[middle] < work.points[i].z: low = middle + 1
      else: high = middle
    work.points[i].zRank = low + 1
    work.sourceOrder[i] = i

  if groupCount > 1: cdq(work, 0, groupCount - 1, zCount)
  for i in 0 ..< n:
    let group = work.originalGroup[i]
    let count = work.dominated[group] + work.points[group].multiplicity - 1
    result += int64(i + 1) * count

proc cdq_three_dimensional_dominance*(input: ptr UncheckedArray[int64],
    length: csize_t): int64 {.cdecl, exportc: "cdq_three_dimensional_dominance".} =
  solve(input, int(length))
