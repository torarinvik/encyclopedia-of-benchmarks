## Clean-room bounded MUMmerGPU maximal exact-match query; see package LICENSE.txt.
const MaxRef = 32
const MaxQuery = 32
const Alphabet = 5
const MaxNodes = 1 + MaxRef * (MaxRef + 3) div 2
const MaxMatches = MaxRef * MaxQuery

proc suffixLess(reference: openArray[int64], refLength, left, right: int): bool =
  var a = left
  var b = right
  while a < refLength and b < refLength and reference[a] == reference[b]:
    inc a
    inc b
  if a == refLength and b == refLength: return false
  if a == refLength: return false
  if b == refLength: return true
  reference[a] < reference[b]

proc putI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc rodinia_mummergpu*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "rodinia_mummergpu".} =
  if input.isNil or length < 5 or length > csize_t(3 + MaxRef + MaxQuery): return -1
  if input[0] < 1 or input[0] > int64(MaxRef) or input[1] < 1 or input[1] > int64(MaxQuery) or input[2] < 1 or input[2] > int64(MaxQuery): return -1
  let refLength = int(input[0]); let queryLength = int(input[1]); let minLength = int(input[2])
  if length != csize_t(3 + refLength + queryLength): return -1
  var reference: array[MaxRef, int64]
  var query: array[MaxQuery, int64]
  for i in 0 ..< refLength:
    let code = input[3 + i]
    if code < 0 or code > 3: return -1
    reference[i] = code
  for i in 0 ..< queryLength:
    let code = input[3 + refLength + i]
    if code < 0 or code > 3: return -1
    query[i] = code

  var children: array[MaxNodes * Alphabet, int32]
  var pathNode: array[MaxRef * (MaxRef + 1), int32]
  var suffixOrder: array[MaxRef, int]
  for i in 0 ..< children.len: children[i] = -1
  for i in 0 ..< pathNode.len: pathNode[i] = -1
  var nodeCount = 1
  for start in 0 ..< refLength:
    var node = 0
    var depth = 0
    pathNode[start * (MaxRef + 1)] = 0
    for pos in start ..< refLength:
      let slot = node * Alphabet + int(reference[pos])
      if children[slot] < 0:
        let fresh = nodeCount
        inc nodeCount
        children[slot] = int32(fresh)
        for symbol in 0 ..< Alphabet: children[fresh * Alphabet + symbol] = -1
      node = int(children[slot])
      inc depth
      pathNode[start * (MaxRef + 1) + depth] = int32(node)
    let terminalSlot = node * Alphabet + 4
    if children[terminalSlot] < 0:
      let fresh = nodeCount
      inc nodeCount
      children[terminalSlot] = int32(fresh)
      for symbol in 0 ..< Alphabet: children[fresh * Alphabet + symbol] = -1

  for i in 0 ..< refLength: suffixOrder[i] = i
  for i in 1 ..< refLength:
    let key = suffixOrder[i]
    var j = i
    while j > 0 and suffixLess(reference, refLength, key, suffixOrder[j - 1]):
      suffixOrder[j] = suffixOrder[j - 1]
      dec j
    suffixOrder[j] = key

  var records: array[MaxMatches * 3, int64]
  var matchCount = 0
  for qstart in 0 ..< queryLength:
    var candidate: array[MaxRef, int]
    for rstart in 0 ..< refLength: candidate[rstart] = -1
    var node = 0
    var depth = 0
    while true:
      let queryHasNext = qstart + depth < queryLength
      for rstart in 0 ..< refLength:
        if pathNode[rstart * (MaxRef + 1) + depth] != int32(node): continue
        let suffixEnds = rstart + depth == refLength
        if suffixEnds or not queryHasNext or reference[rstart + depth] != query[qstart + depth]:
          candidate[rstart] = depth
      if not queryHasNext: break
      let slot = node * Alphabet + int(query[qstart + depth])
      if children[slot] < 0: break
      node = int(children[slot])
      inc depth
    for order in 0 ..< refLength:
      let rstart = suffixOrder[order]
      let matchLength = candidate[rstart]
      if matchLength < minLength: continue
      if qstart > 0 and rstart > 0 and query[qstart - 1] == reference[rstart - 1]: continue
      records[3 * matchCount] = int64(rstart + 1)
      records[3 * matchCount + 1] = int64(qstart + 1)
      records[3 * matchCount + 2] = int64(matchLength)
      inc matchCount

  let outputBytes = matchCount * 24
  if output.isNil or capacity < csize_t(outputBytes): return -2
  for i in 0 ..< 3 * matchCount: putI64(output, i * 8, records[i])
  int64(outputBytes)
