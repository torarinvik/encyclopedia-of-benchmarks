const MaxSide = 8
const MaxQueries = 32
const MaxValue = 7
const MaxParseableInputLength = 195

type RectangleQuery = object
  topBlock, leftBlock, bottomBlock, rightBlock: int
  top, left, bottom, right, ordinal: int

proc queryBefore(a, b: RectangleQuery): bool =
  if a.topBlock != b.topBlock: return a.topBlock < b.topBlock
  if a.leftBlock != b.leftBlock: return a.leftBlock < b.leftBlock
  if a.bottomBlock != b.bottomBlock: return a.bottomBlock < b.bottomBlock
  if a.rightBlock != b.rightBlock: return a.rightBlock < b.rightBlock
  if a.top != b.top: return a.top < b.top
  if a.left != b.left: return a.left < b.left
  if a.bottom != b.bottom: return a.bottom < b.bottom
  if a.right != b.right: return a.right < b.right
  a.ordinal < b.ordinal

proc addValue(value: int, frequencies: var array[MaxValue + 1, int64], statistic: var int64) =
  let oldFrequency = frequencies[value]
  statistic += 2 * oldFrequency + 1
  frequencies[value] = oldFrequency + 1

proc removeValue(value: int, frequencies: var array[MaxValue + 1, int64], statistic: var int64) =
  let oldFrequency = frequencies[value]
  statistic += 1 - 2 * oldFrequency
  frequencies[value] = oldFrequency - 1

proc mo_2d_rectangle_frequency_square*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "mo_2d_rectangle_frequency_square".} =
  if input == nil or length < csize_t(2) or length > csize_t(MaxParseableInputLength):
    return -1
  let sideValue = input[0]
  let queryCountValue = input[1]
  if sideValue < 1 or sideValue > MaxSide or queryCountValue < 0 or queryCountValue > MaxQueries:
    return -1
  let side = int(sideValue)
  let queryCount = int(queryCountValue)
  let matrixEnd = 2 + side * side
  if length != csize_t(matrixEnd + 4 * queryCount):
    return -1

  var matrix: array[MaxSide * MaxSide, int]
  for position in 0 ..< side * side:
    let value = input[2 + position]
    if value < 0 or value > MaxValue: return -1
    matrix[position] = int(value)

  var queries: array[MaxQueries, RectangleQuery]
  for ordinal in 0 ..< queryCount:
    let offset = matrixEnd + 4 * ordinal
    let topValue = input[offset]
    let leftValue = input[offset + 1]
    let bottomValue = input[offset + 2]
    let rightValue = input[offset + 3]
    if topValue < 0 or bottomValue < topValue or bottomValue >= sideValue or
        leftValue < 0 or rightValue < leftValue or rightValue >= sideValue:
      return -1
    let top = int(topValue)
    let left = int(leftValue)
    let bottom = int(bottomValue)
    let right = int(rightValue)
    queries[ordinal] = RectangleQuery(
      topBlock: 0, leftBlock: 0, bottomBlock: 0, rightBlock: 0,
      top: top, left: left, bottom: bottom, right: right, ordinal: ordinal)

  var blockSize = 0
  let sideFourth = side * side * side * side
  for candidate in 1 .. side:
    if queryCount * candidate * candidate * candidate * candidate <= sideFourth:
      blockSize = candidate
  if blockSize == 0: blockSize = 1

  for ordinal in 0 ..< queryCount:
    queries[ordinal].topBlock = queries[ordinal].top div blockSize
    queries[ordinal].leftBlock = queries[ordinal].left div blockSize
    queries[ordinal].bottomBlock = queries[ordinal].bottom div blockSize
    queries[ordinal].rightBlock = queries[ordinal].right div blockSize
  for i in 1 ..< queryCount:
    let current = queries[i]
    var position = i
    while position > 0 and queryBefore(current, queries[position - 1]):
      queries[position] = queries[position - 1]
      dec position
    queries[position] = current

  var answers: array[MaxQueries, int64]
  if queryCount == 0: return 0

  var frequencies: array[MaxValue + 1, int64]
  var statistic = 0'i64
  var top = queries[0].top
  var left = queries[0].left
  var bottom = queries[0].bottom
  var right = queries[0].right
  for row in top .. bottom:
    for column in left .. right:
      addValue(matrix[row * side + column], frequencies, statistic)
  answers[queries[0].ordinal] = statistic

  for sortedIndex in 1 ..< queryCount:
    let query = queries[sortedIndex]
    while top > query.top:
      dec top
      for column in left .. right:
        addValue(matrix[top * side + column], frequencies, statistic)
    while bottom < query.bottom:
      inc bottom
      for column in left .. right:
        addValue(matrix[bottom * side + column], frequencies, statistic)
    while left > query.left:
      dec left
      for row in top .. bottom:
        addValue(matrix[row * side + left], frequencies, statistic)
    while right < query.right:
      inc right
      for row in top .. bottom:
        addValue(matrix[row * side + right], frequencies, statistic)

    while top < query.top:
      for column in left .. right:
        removeValue(matrix[top * side + column], frequencies, statistic)
      inc top
    while bottom > query.bottom:
      for column in left .. right:
        removeValue(matrix[bottom * side + column], frequencies, statistic)
      dec bottom
    while left < query.left:
      for row in top .. bottom:
        removeValue(matrix[row * side + left], frequencies, statistic)
      inc left
    while right > query.right:
      for row in top .. bottom:
        removeValue(matrix[row * side + right], frequencies, statistic)
      dec right
    answers[query.ordinal] = statistic

  var checksum = 0'i64
  for ordinal in 0 ..< queryCount:
    checksum += int64(ordinal + 1) * answers[ordinal]
  checksum
