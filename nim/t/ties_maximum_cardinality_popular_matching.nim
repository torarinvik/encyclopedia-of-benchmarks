# Bounded clean-room tied-list maximum-cardinality popular matching.
const MaxA = 4
const MaxP = 4
const MaxR = 8
const MaxNodes = 12
const MaxInput = 52

type EdgeMatrix = array[MaxA, array[MaxR, bool]]
type RankMatrix = array[MaxA, array[MaxP, int]]
type LeftMatch = array[MaxA, int]
type RightMatch = array[MaxR, int]

proc mpAugment(a, rightCount: int, edges: EdgeMatrix,
               left: var LeftMatch, right: var RightMatch,
               seen: var array[MaxR, bool]): bool =
  for p in 0 ..< rightCount:
    if not edges[a][p] or seen[p]: continue
    seen[p] = true
    let previous = right[p]
    if previous < 0 or mpAugment(previous, rightCount, edges, left, right, seen):
      right[p] = a
      left[a] = p
      return true
  false

proc mpMaximum(applicants, rightCount: int, edges: EdgeMatrix,
               initial: LeftMatch, left: var LeftMatch,
               right: var RightMatch): bool =
  left = initial
  for p in 0 ..< MaxR: right[p] = -1
  for a in 0 ..< applicants:
    if left[a] >= 0:
      let p = left[a]
      if p >= rightCount or right[p] >= 0 or not edges[a][p]: return false
      right[p] = a
  while true:
    var changed = false
    for a in 0 ..< applicants:
      if left[a] < 0:
        var seen: array[MaxR, bool]
        if mpAugment(a, rightCount, edges, left, right, seen): changed = true
    if not changed: return true

proc mpSolve(applicants, posts: int, ranks: RankMatrix,
             maxRank: array[MaxA, int]): int64 =
  let rightCount = posts + applicants
  var firstEdges: EdgeMatrix
  for a in 0 ..< applicants:
    for p in 0 ..< posts: firstEdges[a][p] = ranks[a][p] == 1
  var empty: LeftMatch
  for a in 0 ..< MaxA: empty[a] = -1
  var firstLeft: LeftMatch
  var firstRight: RightMatch
  if not mpMaximum(applicants, rightCount, firstEdges, empty, firstLeft, firstRight): return 0
  var firstSize = 0
  for a in 0 ..< applicants:
    if firstLeft[a] >= 0: inc firstSize

  var state: array[MaxNodes, int]
  for i in 0 ..< MaxNodes: state[i] = -1
  var queue: array[MaxNodes, int]
  var tail = 0
  for a in 0 ..< applicants:
    if firstLeft[a] < 0: state[a] = 0; queue[tail] = a; inc tail
  for p in 0 ..< posts:
    if firstRight[p] < 0:
      let node = applicants + p
      state[node] = 0; queue[tail] = node; inc tail
  for a in 0 ..< applicants:
    let node = applicants + posts + a
    state[node] = 0; queue[tail] = node; inc tail
  var head = 0
  while head < tail:
    let node = queue[head]
    inc head
    if node < applicants:
      let a = node
      if state[node] == 0:
        for p in 0 ..< posts:
          if ranks[a][p] == 1 and firstLeft[a] != p:
            let target = applicants + p
            if state[target] < 0: state[target] = 1; queue[tail] = target; inc tail
      elif firstLeft[a] >= 0:
        let target = applicants + firstLeft[a]
        if state[target] < 0: state[target] = 0; queue[tail] = target; inc tail
    else:
      let p = node - applicants
      if p < posts:
        if state[node] == 0:
          for a in 0 ..< applicants:
            if ranks[a][p] == 1 and firstLeft[a] != p and state[a] < 0:
              state[a] = 1; queue[tail] = a; inc tail
        elif firstRight[p] >= 0:
          let target = firstRight[p]
          if state[target] < 0: state[target] = 0; queue[tail] = target; inc tail

  var classes: array[MaxNodes, int]
  for i in 0 ..< applicants + rightCount:
    classes[i] = if state[i] < 0: 2 else: state[i]
  var allowed: EdgeMatrix
  for a in 0 ..< applicants:
    var bestEven = posts + 1
    for p in 0 ..< posts:
      if ranks[a][p] > 0 and classes[applicants + p] == 0:
        bestEven = min(bestEven, ranks[a][p])
    let lastRank = maxRank[a] + 1
    if classes[applicants + posts + a] == 0: bestEven = min(bestEven, lastRank)
    for p in 0 ..< posts:
      let rank = ranks[a][p]
      if rank != 1 and not (rank > 0 and rank == bestEven and classes[applicants + p] == 0): continue
      let ac = classes[a]
      let pc = classes[applicants + p]
      if (ac == 1 and pc in {1, 2}) or (ac == 2 and pc == 1): continue
      allowed[a][p] = true
    if lastRank == bestEven and classes[applicants + posts + a] == 0:
      let p = posts + a
      let ac = classes[a]
      let pc = classes[applicants + p]
      if not ((ac == 1 and pc in {1, 2}) or (ac == 2 and pc == 1)): allowed[a][p] = true
  for a in 0 ..< applicants:
    if firstLeft[a] >= 0 and not allowed[a][firstLeft[a]]: return 0

  var popularLeft: LeftMatch
  var tempRight: RightMatch
  if not mpMaximum(applicants, rightCount, allowed, firstLeft, popularLeft, tempRight): return 0
  var rankOne = 0
  for a in 0 ..< applicants:
    if popularLeft[a] < 0: return 0
    if popularLeft[a] < posts and ranks[a][popularLeft[a]] == 1: inc rankOne
  if rankOne != firstSize: return 0

  var realEdges: EdgeMatrix
  var initialReal: LeftMatch
  for a in 0 ..< MaxA: initialReal[a] = -1
  for a in 0 ..< applicants:
    if popularLeft[a] < posts: initialReal[a] = popularLeft[a]
    for p in 0 ..< posts: realEdges[a][p] = allowed[a][p]
  var realLeft: LeftMatch
  if not mpMaximum(applicants, rightCount, realEdges, initialReal, realLeft, tempRight): return 0
  rankOne = 0
  for a in 0 ..< applicants:
    if realLeft[a] >= 0 and realLeft[a] < posts and ranks[a][realLeft[a]] == 1: inc rankOne
  if rankOne != firstSize: return 0

  var finalLeft: LeftMatch
  if not mpMaximum(applicants, rightCount, allowed, realLeft, finalLeft, tempRight): return 0
  var result = 0
  rankOne = 0
  for a in 0 ..< applicants:
    if finalLeft[a] < 0: return 0
    if finalLeft[a] < posts:
      inc result
      if ranks[a][finalLeft[a]] == 1: inc rankOne
  if rankOne != firstSize: return 0
  int64(result)

proc ties_maximum_cardinality_popular_matching*(input: ptr UncheckedArray[int64],
    length: csize_t): int64 {.cdecl, exportc: "ties_maximum_cardinality_popular_matching".} =
  if input == nil or length < 3 or length > MaxInput: return -1
  let av = input[0]
  let pv = input[1]
  let ev = input[2]
  if av < 1 or av > MaxA or pv < 1 or pv > MaxP or ev < av or ev > av * pv: return -1
  let applicants = int(av)
  let posts = int(pv)
  let edgeCount = int(ev)
  if length != csize_t(3 + 3 * edgeCount): return -1
  var ranks: RankMatrix
  var maxRank: array[MaxA, int]
  var cursor = 3
  for i in 0 ..< edgeCount:
    let a64 = input[cursor]
    let p64 = input[cursor + 1]
    let r64 = input[cursor + 2]
    cursor += 3
    if a64 < 0 or a64 >= av or p64 < 0 or p64 >= pv or r64 < 1 or r64 > pv: return -1
    let a = int(a64)
    let p = int(p64)
    let rank = int(r64)
    if ranks[a][p] != 0: return -1
    ranks[a][p] = rank
    maxRank[a] = max(maxRank[a], rank)
  var hasTie = false
  for a in 0 ..< applicants:
    if maxRank[a] == 0: return -1
    var counts: array[MaxP + 1, int]
    for p in 0 ..< posts:
      if ranks[a][p] > 0: inc counts[ranks[a][p]]
    for rank in 1 .. maxRank[a]:
      if counts[rank] == 0: return -1
      if counts[rank] > 1: hasTie = true
  if not hasTie: return -1
  mpSolve(applicants, posts, ranks, maxRank)
