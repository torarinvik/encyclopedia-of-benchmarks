const MaxGridSide = 5
const MaxPaths = 3
const MaxInputLength = 11

proc permutationTerm(matrix: array[MaxPaths, array[MaxPaths, int64]], permutation: array[MaxPaths, int], count: int): int64 =
  var product = 1'i64
  var inversions = 0
  for row in 0 ..< count:
    product *= matrix[row][permutation[row]]
    for other in row + 1 ..< count:
      if permutation[row] > permutation[other]: inc inversions
  if (inversions and 1) != 0: -product else: product

proc determinant(matrix: array[MaxPaths, array[MaxPaths, int64]], count: int): int64 =
  var total = 0'i64
  var permutation: array[MaxPaths, int]
  let secondLimit = if count >= 2: count else: 1
  let thirdLimit = if count >= 3: count else: 1
  for first in 0 ..< count:
    permutation[0] = first
    for second in 0 ..< secondLimit:
      if count >= 2 and second == first: continue
      permutation[1] = second
      for third in 0 ..< thirdLimit:
        if count >= 3 and (third == first or third == second): continue
        permutation[2] = third
        total += permutationTerm(matrix, permutation, count)
  total

proc lgv_nonintersecting_paths*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "lgv_nonintersecting_paths".} =
  if input == nil or length < 4 or length > csize_t(MaxInputLength): return -1
  let height64 = input[0]
  let width64 = input[1]
  let pathCount64 = input[2]
  let blockedMask = input[3]
  if height64 < 1 or height64 > int64(MaxGridSide) or width64 < 2 or width64 > int64(MaxGridSide) or
      pathCount64 < 1 or pathCount64 > int64(MaxPaths) or blockedMask < 0: return -1
  let height = int(height64)
  let width = int(width64)
  let pathCount = int(pathCount64)
  if length != csize_t(4 + 2 * pathCount): return -1

  var sourceRows: array[MaxPaths, int]
  var sinkRows: array[MaxPaths, int]
  var previous = -1
  for i in 0 ..< pathCount:
    let row = input[4 + i]
    if row < 0 or row >= height64 or row <= int64(previous): return -1
    sourceRows[i] = int(row)
    previous = int(row)
  previous = -1
  for i in 0 ..< pathCount:
    let row = input[4 + pathCount + i]
    if row < 0 or row >= height64 or row <= int64(previous) or int64(sourceRows[i]) > row: return -1
    sinkRows[i] = int(row)
    previous = int(row)

  var maskLimit = 1'i64
  for cell in 0 ..< height * width: maskLimit *= 2
  if blockedMask >= maskLimit: return -1
  var blocked: array[MaxGridSide * MaxGridSide, bool]
  var remainingMask = blockedMask
  for cell in 0 ..< height * width:
    blocked[cell] = (remainingMask and 1'i64) != 0
    remainingMask = remainingMask shr 1
  for i in 0 ..< pathCount:
    if blocked[sourceRows[i] * width] or blocked[sinkRows[i] * width + width - 1]: return -1

  var matrix: array[MaxPaths, array[MaxPaths, int64]]
  for sourceIndex in 0 ..< pathCount:
    var paths: array[MaxGridSide, array[MaxGridSide, int64]]
    let sourceRow = sourceRows[sourceIndex]
    paths[sourceRow][0] = 1
    for row in sourceRow ..< height:
      for column in 0 ..< width:
        let cell = row * width + column
        if blocked[cell]:
          paths[row][column] = 0
        elif row == sourceRow and column == 0:
          paths[row][column] = 1
        else:
          if row > sourceRow: paths[row][column] += paths[row - 1][column]
          if column > 0: paths[row][column] += paths[row][column - 1]
    for sinkIndex in 0 ..< pathCount:
      matrix[sourceIndex][sinkIndex] = paths[sinkRows[sinkIndex]][width - 1]

  determinant(matrix, pathCount)
