const MaxSymbols = 12
const MaxLevels = 10
const MaxItems = 24
const MaxParseableInputLength = 15

proc length_limited_huffman_package_merge*(input: ptr UncheckedArray[int64],
    length: csize_t): int64 {.cdecl, exportc: "length_limited_huffman_package_merge".} =
  if input.isNil or length < csize_t(4) or length > csize_t(MaxParseableInputLength): return -1
  let nValue = input[0]
  let limitValue = input[1]
  if nValue < 2'i64 or nValue > int64(MaxSymbols) or
      limitValue < 1'i64 or limitValue > 6'i64 or
      nValue > (1'i64 shl int(limitValue)):
    return -1
  let n = int(nValue)
  let limit = int(limitValue)
  if length != csize_t(n + 2): return -1

  var weights: array[MaxSymbols, int64]
  for i in 0..<n:
    let weight = input[i + 2]
    if weight < 0'i64 or weight > 1_000_000'i64: return -1
    weights[i] = weight
  for i in 1..<n:
    let key = weights[i]
    var j = i
    while j > 0 and weights[j - 1] > key:
      weights[j] = weights[j - 1]
      dec j
    weights[j] = key

  var lists: array[MaxLevels, array[MaxItems, int64]]
  var counts: array[MaxLevels, int]
  for level in 0..<limit:
    for i in 0..<n: lists[level][i] = weights[i]
    counts[level] = n

  var remaining = int64(n - 1) shl limit
  var total = 0'i64
  var level = 0
  while remaining > 0'i64:
    while level < MaxLevels and counts[level] == 0: inc level
    if level >= MaxLevels: return -1

    let width = 1'i64 shl level
    let needed = remaining and -remaining
    if width > needed: return -1
    if width == needed:
      total += lists[level][0]
      for i in 1..<counts[level]: lists[level][i - 1] = lists[level][i]
      dec counts[level]
      remaining -= width
      if remaining == 0'i64: break

    let packageCount = counts[level] div 2
    var packages: array[MaxItems, int64]
    for i in 0..<packageCount:
      packages[i] = lists[level][2 * i] + lists[level][2 * i + 1]
    counts[level] = 0

    let nextLevel = level + 1
    if nextLevel >= MaxLevels: return -1
    var merged: array[MaxItems, int64]
    var packageIndex = 0
    var existingIndex = 0
    var mergedCount = 0
    while packageIndex < packageCount and existingIndex < counts[nextLevel]:
      if packages[packageIndex] <= lists[nextLevel][existingIndex]:
        if mergedCount >= MaxItems: return -1
        merged[mergedCount] = packages[packageIndex]
        inc packageIndex
      else:
        if mergedCount >= MaxItems: return -1
        merged[mergedCount] = lists[nextLevel][existingIndex]
        inc existingIndex
      inc mergedCount
    while packageIndex < packageCount:
      if mergedCount >= MaxItems: return -1
      merged[mergedCount] = packages[packageIndex]
      inc packageIndex
      inc mergedCount
    while existingIndex < counts[nextLevel]:
      if mergedCount >= MaxItems: return -1
      merged[mergedCount] = lists[nextLevel][existingIndex]
      inc existingIndex
      inc mergedCount
    lists[nextLevel] = merged
    counts[nextLevel] = mergedCount
    level = nextLevel

  total
