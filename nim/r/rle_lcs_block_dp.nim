## Run-length-native LCS by run-pair blocks and boundary propagation.
proc rle_lcs_block_dp*(packed: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "rle_lcs_block_dp".} =
  if packed.isNil or length < 4 or length > 18: return -1
  let leftCountValue = packed[0]
  if leftCountValue < 1 or leftCountValue > 4: return -1
  let leftCount = int(leftCountValue)
  let rightCountIndex = 1 + 2 * leftCount
  if rightCountIndex >= int(length): return -1
  let rightCountValue = packed[rightCountIndex]
  if rightCountValue < 1 or rightCountValue > 4 or
      int(length) != rightCountIndex + 1 + 2 * int(rightCountValue): return -1
  let rightCount = int(rightCountValue)
  var leftSymbol: array[4, int64]
  var leftSize: array[4, int]
  var rightSymbol: array[4, int64]
  var rightSize: array[4, int]
  var leftTotal = 0
  var rightTotal = 0
  for run in 0 ..< leftCount:
    let symbol = packed[1 + 2 * run]
    let size = packed[2 + 2 * run]
    if symbol < 0 or symbol > 3 or size < 1 or size > 8: return -1
    leftTotal += int(size)
    if leftTotal > 16: return -1
    leftSymbol[run] = symbol
    leftSize[run] = int(size)
  for run in 0 ..< rightCount:
    let symbol = packed[rightCountIndex + 1 + 2 * run]
    let size = packed[rightCountIndex + 2 + 2 * run]
    if symbol < 0 or symbol > 3 or size < 1 or size > 8: return -1
    rightTotal += int(size)
    if rightTotal > 16: return -1
    rightSymbol[run] = symbol
    rightSize[run] = int(size)

  var bottom: array[4, array[9, int64]]
  var nextBottom: array[4, array[9, int64]]
  for i in 0 ..< leftCount:
    var leftBoundary: array[9, int64]
    for j in 0 ..< rightCount:
      let rows = leftSize[i]
      let columns = rightSize[j]
      var previous: array[9, int64]
      var current: array[9, int64]
      var rightBoundary: array[9, int64]
      for column in 0 .. columns: previous[column] = bottom[j][column]
      rightBoundary[0] = previous[columns]
      for row in 1 .. rows:
        current[0] = leftBoundary[row]
        for column in 1 .. columns:
          if leftSymbol[i] == rightSymbol[j]:
            current[column] = previous[column - 1] + 1
          else:
            current[column] = max(previous[column], current[column - 1])
        rightBoundary[row] = current[columns]
        for column in 0 .. columns: previous[column] = current[column]
      for column in 0 .. columns: nextBottom[j][column] = previous[column]
      for row in 0 .. rows: leftBoundary[row] = rightBoundary[row]
    for j in 0 ..< rightCount:
      for column in 0 .. rightSize[j]: bottom[j][column] = nextBottom[j][column]
  bottom[rightCount - 1][rightSize[rightCount - 1]]
