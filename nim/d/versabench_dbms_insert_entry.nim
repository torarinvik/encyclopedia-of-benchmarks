const MaxDepth = 2
const MaxChildren = 4
const MaxLeaf = 3
const MaxWords = 28

proc validBox(b: array[8, int64]): bool =
  for d in 0 ..< 4:
    if b[d] < -8 or b[d] > 8 or b[4+d] < -8 or b[4+d] > 8 or b[d] >= b[4+d]: return false
  true

proc unionBoxes(boxes: openArray[array[8, int64]]): array[8, int64] =
  result = boxes[0]
  for i in 1 ..< boxes.len:
    for d in 0 ..< 4:
      result[d] = min(result[d], boxes[i][d])
      result[4+d] = max(result[4+d], boxes[i][4+d])

proc volume(b: array[8, int64]): int64 =
  result = 1
  for d in 0 ..< 4: result *= b[4+d] - b[d]

proc sameBox(a, b: array[8, int64]): bool = a == b

proc writeI64(output: ptr UncheckedArray[byte], word: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8: output[word*8+b] = byte((bits shr (8*b)) and 255)

proc versabench_dbms_insert_entry*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[byte], outputCapacity: csize_t): int64
    {.cdecl, exportc: "versabench_dbms_insert_entry".} =
  if values == nil or length < 11 or length > 105: return -1
  let depthValue = values[0]; let newId = values[1]
  if depthValue < 0 or depthValue > MaxDepth or newId < 0 or newId >= 32: return -1
  let depth = int(depthValue)
  var incoming: array[8, int64]
  for i in 0 ..< 8: incoming[i] = values[2+i]
  if not validBox(incoming): return -1
  var branches: array[MaxDepth, array[MaxChildren, array[8, int64]]]
  var counts: array[MaxDepth, int]
  var pos = 10
  for level in 0 ..< depth:
    if pos >= int(length): return -1
    let countValue = values[pos]; pos += 1
    if countValue < 1 or countValue > MaxChildren or pos + int(countValue)*8 > int(length): return -1
    counts[level] = int(countValue)
    for i in 0 ..< counts[level]:
      for j in 0 ..< 8: branches[level][i][j] = values[pos+j]
      pos += 8
      if not validBox(branches[level][i]): return -1
  if pos >= int(length): return -1
  let leafValue = values[pos]; pos += 1
  if leafValue < 0 or leafValue > MaxLeaf or (depth > 0 and leafValue == 0) or pos + int(leafValue)*9 > int(length): return -1
  let leafCount = int(leafValue)
  var leafBoxes: array[MaxLeaf, array[8, int64]]
  var leafIds: array[MaxLeaf, int64]
  var seen: array[32, bool]
  for i in 0 ..< leafCount:
    for j in 0 ..< 8: leafBoxes[i][j] = values[pos+j]
    pos += 8
    leafIds[i] = values[pos]; pos += 1
    if not validBox(leafBoxes[i]) or leafIds[i] < 0 or leafIds[i] >= 32 or seen[int(leafIds[i])]: return -1
    seen[int(leafIds[i])] = true
  if pos != int(length) or seen[int(newId)]: return -1
  var choices: array[MaxDepth, int]
  for level in 0 ..< depth:
    var best = 65536'i64
    for i in 0 ..< counts[level]:
      var joined: array[8, int64]
      for d in 0 ..< 4:
        joined[d] = min(branches[level][i][d], incoming[d])
        joined[4+d] = max(branches[level][i][4+d], incoming[4+d])
      let penalty = volume(joined) - volume(branches[level][i])
      if penalty < best: best = penalty; choices[level] = i
  if depth > 0:
    var pre = unionBoxes(leafBoxes.toOpenArray(0, leafCount-1))
    for rev in countdown(depth-1, 0):
      if branches[rev][choices[rev]] != pre: return -1
      pre = unionBoxes(branches[rev].toOpenArray(0, counts[rev]-1))
  var staged: array[MaxLeaf+1, array[8, int64]]
  for i in 0 ..< leafCount: staged[i] = leafBoxes[i]
  staged[leafCount] = incoming
  var child = unionBoxes(staged.toOpenArray(0, leafCount))
  var resultWords: array[MaxWords, int64]
  var outCount = 0
  resultWords[outCount] = depth; outCount += 1
  resultWords[outCount] = newId; outCount += 1
  for i in 0 ..< depth: resultWords[outCount] = choices[i]; outCount += 1
  for d in 0 ..< 8: resultWords[outCount] = child[d]; outCount += 1
  for rev in countdown(depth-1, 0):
    branches[rev][choices[rev]] = child
    child = unionBoxes(branches[rev].toOpenArray(0, counts[rev]-1))
    for d in 0 ..< 8: resultWords[outCount] = child[d]; outCount += 1
  let bytes = outCount * 8
  if output == nil or outputCapacity < csize_t(bytes): return -2
  for i in 0 ..< outCount: writeI64(output, i, resultWords[i])
  int64(bytes)
