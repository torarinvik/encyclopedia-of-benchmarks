## Run-length-native unit-cost edit distance by run-pair blocks.
proc rle_levenshtein_block_dp*(packed: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "rle_levenshtein_block_dp".} =
  if packed.isNil or length < 4 or length > 18: return -1
  let leftCountRaw = packed[0]
  if leftCountRaw < 1 or leftCountRaw > 4: return -1
  let leftCount = int(leftCountRaw)
  let rightIndex = 1 + 2 * leftCount
  if rightIndex >= int(length): return -1
  let rightCountRaw = packed[rightIndex]
  if rightCountRaw < 1 or rightCountRaw > 4 or int(length) != rightIndex + 1 + 2 * int(rightCountRaw): return -1
  let rightCount = int(rightCountRaw)
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
    leftSymbol[run] = symbol; leftSize[run] = int(size)
  for run in 0 ..< rightCount:
    let symbol = packed[rightIndex + 1 + 2 * run]
    let size = packed[rightIndex + 2 + 2 * run]
    if symbol < 0 or symbol > 3 or size < 1 or size > 8: return -1
    rightTotal += int(size)
    if rightTotal > 16: return -1
    rightSymbol[run] = symbol; rightSize[run] = int(size)

  var bottom: array[4, array[9, int64]]
  var nextBottom: array[4, array[9, int64]]
  var rightPrefix = 0
  for j in 0 ..< rightCount:
    for column in 0 .. rightSize[j]: bottom[j][column] = int64(rightPrefix + column)
    rightPrefix += rightSize[j]
  var leftPrefix = 0
  for i in 0 ..< leftCount:
    let rows = leftSize[i]
    var leftBoundary: array[9, int64]
    for row in 0 .. rows: leftBoundary[row] = int64(leftPrefix + row)
    for j in 0 ..< rightCount:
      let columns = rightSize[j]
      var previous: array[9, int64]
      var current: array[9, int64]
      var rightBoundary: array[9, int64]
      for column in 0 .. columns: previous[column] = bottom[j][column]
      rightBoundary[0] = previous[columns]
      let substitution = if leftSymbol[i] == rightSymbol[j]: 0'i64 else: 1'i64
      for row in 1 .. rows:
        current[0] = leftBoundary[row]
        for column in 1 .. columns:
          current[column] = min(min(previous[column] + 1, current[column - 1] + 1),
                                previous[column - 1] + substitution)
        rightBoundary[row] = current[columns]
        for column in 0 .. columns: previous[column] = current[column]
      for column in 0 .. columns: nextBottom[j][column] = previous[column]
      for row in 0 .. rows: leftBoundary[row] = rightBoundary[row]
    for j in 0 ..< rightCount:
      for column in 0 .. rightSize[j]: bottom[j][column] = nextBottom[j][column]
    leftPrefix += rows
  bottom[rightCount - 1][rightSize[rightCount - 1]]
