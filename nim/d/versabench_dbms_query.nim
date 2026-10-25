const MaxNodes = 7
const MaxEntries = 4
const MaxRecords = 16
type
  BoxEntry = object
    lo: array[4, int64]
    hi: array[4, int64]
    reference: int64
  TreeNode = object
    level: int64
    count: int
    entries: array[MaxEntries, BoxEntry]

proc validBox(lo, hi: array[4, int64]): bool =
  for d in 0 ..< 4:
    if lo[d] < -8 or lo[d] > 8 or hi[d] < -8 or hi[d] > 8 or lo[d] >= hi[d]: return false
  true

proc intersects(e: BoxEntry, lo, hi: array[4, int64]): bool =
  for d in 0 ..< 4:
    if lo[d] > e.hi[d] or e.lo[d] > hi[d]: return false
  true

proc writeI64(output: ptr UncheckedArray[byte], word: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8: output[word*8+b] = byte((bits shr (8*b)) and 255)

proc versabench_dbms_query*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[byte], outputCapacity: csize_t): int64
    {.cdecl, exportc: "versabench_dbms_query".} =
  if values == nil or length < 10 or length > 277: return -1
  let nodeCountValue = values[0]; let rootValue = values[1]
  if nodeCountValue < 1 or nodeCountValue > MaxNodes or rootValue < 0 or rootValue >= nodeCountValue: return -1
  let nodeCount = int(nodeCountValue); let root = int(rootValue)
  var queryLo, queryHi: array[4, int64]
  for d in 0 ..< 4: queryLo[d] = values[2+d]; queryHi[d] = values[6+d]
  if not validBox(queryLo, queryHi): return -1
  var nodes: array[MaxNodes, TreeNode]
  var parents: array[MaxNodes, int]
  var seenIds: array[32, bool]
  var leafTotal = 0
  var pos = 10
  for nodeIndex in 0 ..< nodeCount:
    if pos + 2 > int(length): return -1
    let level = values[pos]; let countValue = values[pos+1]; pos += 2
    if level < 0 or level > 2 or countValue < 1 or countValue > MaxEntries or pos + int(countValue)*9 > int(length): return -1
    let count = int(countValue)
    nodes[nodeIndex].level = level; nodes[nodeIndex].count = count
    for entryIndex in 0 ..< count:
      var e: BoxEntry
      for d in 0 ..< 4: e.lo[d] = values[pos+d]
      pos += 4
      for d in 0 ..< 4: e.hi[d] = values[pos+d]
      pos += 4
      e.reference = values[pos]; pos += 1
      if not validBox(e.lo, e.hi): return -1
      if level == 0:
        if e.reference < 0 or e.reference >= 32 or seenIds[int(e.reference)] or leafTotal >= MaxRecords: return -1
        seenIds[int(e.reference)] = true; leafTotal += 1
      else:
        if e.reference < 0 or e.reference >= nodeCountValue: return -1
        parents[int(e.reference)] += 1
        if parents[int(e.reference)] > 1: return -1
      nodes[nodeIndex].entries[entryIndex] = e
  if pos != int(length) or parents[root] != 0: return -1
  for nodeIndex in 0 ..< nodeCount:
    if nodeIndex != root and parents[nodeIndex] != 1: return -1
    if nodes[nodeIndex].level == 0: continue
    for entryIndex in 0 ..< nodes[nodeIndex].count:
      let branch = nodes[nodeIndex].entries[entryIndex]
      let child = nodes[int(branch.reference)]
      if child.level != nodes[nodeIndex].level - 1: return -1
      for childEntry in 0 ..< child.count:
        for d in 0 ..< 4:
          if branch.lo[d] > child.entries[childEntry].lo[d] or branch.hi[d] < child.entries[childEntry].hi[d]: return -1
  var stack: array[MaxNodes, int]
  var top = 1; stack[0] = root
  var hits: array[MaxRecords, int64]
  var hitCount = 0
  while top > 0:
    top -= 1
    let nodeIndex = stack[top]
    let node = nodes[nodeIndex]
    if node.level == 0:
      for entryIndex in 0 ..< node.count:
        let e = node.entries[entryIndex]
        if intersects(e, queryLo, queryHi):
          hits[hitCount] = e.reference
          hitCount += 1
    else:
      var rev = node.count
      while rev > 0:
        rev -= 1
        let e = node.entries[rev]
        if intersects(e, queryLo, queryHi): stack[top] = int(e.reference); top += 1
  let byteCount = hitCount * 8
  if output == nil or outputCapacity < csize_t(byteCount): return -2
  for i in 0 ..< hitCount: writeI64(output, i, hits[i])
  int64(byteCount)
