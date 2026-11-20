const
  MaxTreeNodes = 15
  MaxTotalNodes = 30
  MaxParseableLength = 93

proc validTree(input: ptr UncheckedArray[int64], offset, nodeCount: int): bool =
  var visited: array[MaxTreeNodes, bool]
  var parents: array[MaxTreeNodes, int]
  var stack: array[MaxTreeNodes, int]
  var top = 1
  var reached = 0
  while top > 0:
    dec top
    let node = stack[top]
    if node < 0 or node >= nodeCount or visited[node]: return false
    visited[node] = true
    inc reached
    let base = offset + 3 * node
    let left = input[base + 1]
    let right = input[base + 2]
    if left == -1 and right == -1: continue
    if left < 0 or right < 0 or left >= int64(nodeCount) or right >= int64(nodeCount) or
        left == right or left == 0 or right == 0: return false
    inc parents[int(left)]
    inc parents[int(right)]
    if parents[int(left)] != 1 or parents[int(right)] != 1: return false
    stack[top] = int(right)
    inc top
    stack[top] = int(left)
    inc top
  if reached != nodeCount or parents[0] != 0: return false
  for node in 1 ..< nodeCount:
    if parents[node] != 1: return false
  true

proc same_fringe_leaf_iterator*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "same_fringe_leaf_iterator".} =
  if input.isNil or length < 2 or length > csize_t(MaxParseableLength): return -1
  let nAWord = input[0]
  let nBWord = input[1]
  if nAWord < 1 or nAWord > MaxTreeNodes.int64 or
      nBWord < 1 or nBWord > MaxTreeNodes.int64: return -1
  let nA = int(nAWord)
  let nB = int(nBWord)
  if nA + nB > MaxTotalNodes or int(length) != 2 + 3 * (nA + nB): return -1
  let offsetA = 2
  let offsetB = 2 + 3 * nA
  if not validTree(input, offsetA, nA) or not validTree(input, offsetB, nB): return -1

  var stackA: array[MaxTreeNodes, int]
  var stackB: array[MaxTreeNodes, int]
  var topA = 1
  var topB = 1
  while true:
    var haveA = false
    var haveB = false
    var leafA = 0'i64
    var leafB = 0'i64
    while topA > 0 and not haveA:
      dec topA
      let node = stackA[topA]
      let base = offsetA + 3 * node
      let left = input[base + 1]
      let right = input[base + 2]
      if left == -1:
        leafA = input[base]
        haveA = true
      else:
        stackA[topA] = int(right)
        inc topA
        stackA[topA] = int(left)
        inc topA
    while topB > 0 and not haveB:
      dec topB
      let node = stackB[topB]
      let base = offsetB + 3 * node
      let left = input[base + 1]
      let right = input[base + 2]
      if left == -1:
        leafB = input[base]
        haveB = true
      else:
        stackB[topB] = int(right)
        inc topB
        stackB[topB] = int(left)
        inc topB
    if not haveA or not haveB:
      if haveA == haveB: return 1
      return 0
    if leafA != leafB: return 0
  return -1
