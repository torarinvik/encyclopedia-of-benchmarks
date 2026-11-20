const MaxWords = 16
const MaxQueries = 8
const MaxWordLength = 10

proc validWord(word: int64): bool =
  if word < 0 or (uint64(word) shr 44) != 0: return false
  let packed = uint64(word)
  let wordLength = int((packed shr 40) and 15'u64)
  if wordLength > MaxWordLength: return false
  for position in 0 ..< MaxWordLength:
    let symbol = int((packed shr (4 * position)) and 15'u64)
    if position < wordLength:
      if symbol == 0: return false
    elif symbol != 0:
      return false
  true

proc editDistance(left, right: int64): int =
  let a = uint64(left)
  let b = uint64(right)
  let n = int((a shr 40) and 15'u64)
  let m = int((b shr 40) and 15'u64)
  var previous: array[MaxWordLength + 1, int]
  var current: array[MaxWordLength + 1, int]
  for j in 0 .. m: previous[j] = j
  for i in 1 .. n:
    current[0] = i
    let aSymbol = (a shr (4 * (i - 1))) and 15'u64
    for j in 1 .. m:
      let bSymbol = (b shr (4 * (j - 1))) and 15'u64
      let replacement = previous[j - 1] + (if aSymbol == bSymbol: 0 else: 1)
      current[j] = min(previous[j] + 1, min(current[j - 1] + 1, replacement))
    previous = current
  previous[m]

proc bk_tree_edit_distance_search*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "bk_tree_edit_distance_search".} =
  if input.isNil or length < csize_t(3) or length > csize_t(28): return -1
  let nValue = input[0]
  let qValue = input[1]
  let radiusValue = input[2]
  if nValue < 0 or nValue > MaxWords or qValue < 0 or qValue > MaxQueries
      or radiusValue < 0 or radiusValue > 3
      or length != csize_t(3 + nValue + qValue): return -1
  let n = int(nValue)
  let q = int(qValue)
  let radius = int(radiusValue)
  for i in 0 ..< n + q:
    if not validWord(input[i + 3]): return -1
  for i in 0 ..< n:
    for j in 0 ..< i:
      if input[i + 3] == input[j + 3]: return -1

  var children: array[MaxWords * (MaxWordLength + 1), int32]
  for i in 0 ..< children.len: children[i] = -1
  for node in 1 ..< n:
    var pivot = 0
    while true:
      let edge = editDistance(input[node + 3], input[pivot + 3])
      let slot = pivot * (MaxWordLength + 1) + edge
      if children[slot] == -1:
        children[slot] = int32(node)
        break
      pivot = int(children[slot])

  var result = 0'i64
  for queryIndex in 0 ..< q:
    var matches = 0'i64
    var indexSum = 0'i64
    if n != 0:
      var stack: array[MaxWords, int]
      var top = 1
      stack[0] = 0
      while top != 0:
        dec top
        let node = stack[top]
        let distance = editDistance(input[3 + n + queryIndex], input[node + 3])
        if distance <= radius:
          inc matches
          indexSum += int64(node)
        let low = max(0, distance - radius)
        let high = min(MaxWordLength, distance + radius)
        for edge in low .. high:
          let child = children[node * (MaxWordLength + 1) + edge]
          if child >= 0:
            stack[top] = int(child)
            inc top
    result += int64(queryIndex + 1) * (17 * matches + indexSum)
  result
