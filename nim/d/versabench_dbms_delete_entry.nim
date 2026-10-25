const MaxWords = 181
proc validBox(b: array[8,int64]): bool =
  for d in 0 ..< 4:
    if b[d] < -8 or b[d] > 8 or b[4+d] < -8 or b[4+d] > 8 or b[d] >= b[4+d]: return false
  true
proc intersects(b,q: array[8,int64]): bool =
  for d in 0 ..< 4:
    if q[d] > b[4+d] or b[d] > q[4+d]: return false
  true
proc unionBoxes(boxes: openArray[array[8,int64]]): array[8,int64] =
  result = boxes[0]
  for i in 1 ..< boxes.len:
    for d in 0 ..< 4:
      result[d] = min(result[d], boxes[i][d]); result[4+d] = max(result[4+d], boxes[i][4+d])
proc putI64(outp: ptr UncheckedArray[byte], word: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8: outp[word*8+b] = byte((bits shr (8*b)) and 255)

proc versabench_dbms_delete_entry*(values: ptr UncheckedArray[int64], length: csize_t, output: ptr UncheckedArray[byte], outputCapacity: csize_t): int64 {.cdecl, exportc: "versabench_dbms_delete_entry".} =
  if values == nil or length < 10 or length > 190: return -1
  let rawChildren = values[0]
  if rawChildren < 1 or rawChildren > 4: return -1
  let childCount = int(rawChildren)
  var query: array[8,int64]
  for i in 0 ..< 8: query[i] = values[1+i]
  if not validBox(query): return -1
  var boxes: array[4,array[4,array[8,int64]]]
  var ids: array[4,array[4,int64]]
  var mbrs: array[4,array[8,int64]]
  var counts: array[4,int]
  var seen: array[32,bool]
  var pos = 9
  for c in 0 ..< childCount:
    if pos+9 > int(length): return -1
    let rawCount = values[pos]; pos += 1
    if rawCount < 1 or rawCount > 4 or pos+8+int(rawCount)*9 > int(length): return -1
    counts[c] = int(rawCount)
    for d in 0 ..< 8: mbrs[c][d] = values[pos+d]
    pos += 8
    if not validBox(mbrs[c]): return -1
    for r in 0 ..< counts[c]:
      for d in 0 ..< 8: boxes[c][r][d] = values[pos+d]
      pos += 8
      ids[c][r] = values[pos]; pos += 1
      if not validBox(boxes[c][r]) or ids[c][r] < 0 or ids[c][r] >= 32 or seen[int(ids[c][r])]: return -1
      seen[int(ids[c][r])] = true
    if unionBoxes(boxes[c].toOpenArray(0, counts[c]-1)) != mbrs[c]: return -1
  if pos != int(length): return -1
  var kept: array[4,array[4,array[8,int64]]]
  var keptIds: array[4,array[4,int64]]
  var keptMbrs: array[4,array[8,int64]]
  var keptCounts: array[4,int]
  var remaining = 0
  for c in 0 ..< childCount:
    var k = 0
    for r in 0 ..< counts[c]:
      if intersects(mbrs[c],query) and intersects(boxes[c][r],query): continue
      kept[c][k] = boxes[c][r]; keptIds[c][k] = ids[c][r]; k += 1
    if k > 0:
      keptCounts[remaining] = k
      for r in 0 ..< k: kept[remaining][r] = kept[c][r]; keptIds[remaining][r] = keptIds[c][r]
      keptMbrs[remaining] = unionBoxes(kept[remaining].toOpenArray(0, k-1))
      remaining += 1
  var words: array[MaxWords,int64]
  var outCount = 0
  words[outCount] = int64(remaining); outCount += 1
  for c in 0 ..< remaining:
    words[outCount] = int64(keptCounts[c]); outCount += 1
    for d in 0 ..< 8: words[outCount] = keptMbrs[c][d]; outCount += 1
    for r in 0 ..< keptCounts[c]:
      for d in 0 ..< 8: words[outCount] = kept[c][r][d]; outCount += 1
      words[outCount] = keptIds[c][r]; outCount += 1
  let bytes = outCount * 8
  if output == nil or outputCapacity < csize_t(bytes): return -2
  for i in 0 ..< outCount: putI64(output, i, words[i])
  int64(bytes)
