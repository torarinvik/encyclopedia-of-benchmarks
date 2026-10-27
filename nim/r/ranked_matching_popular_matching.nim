const MaxA = 4
const MaxP = 4
const MaxPosts = 8
const MaxNodes = 12
const MaxInput = 51
const MaxOutput = 40

proc put64(output: ptr UncheckedArray[uint8], at: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[at + byte] = uint8((bits shr (8 * byte)) and 255)

proc lexLess(left, right: array[MaxA, int], count: int): bool =
  for index in 0 ..< count:
    if left[index] != right[index]: return left[index] < right[index]
  false

proc ranked_matching_popular_matching*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "ranked_matching_popular_matching".} =
  if input.isNil or length < csize_t(6) or length > csize_t(MaxInput): return -1
  let a64 = input[0]
  let p64 = input[1]
  let e64 = input[2]
  if a64 < 1 or a64 > int64(MaxA) or p64 < 1 or p64 > int64(MaxP): return -1
  let applicants = int(a64)
  let posts = int(p64)
  if e64 < a64 or e64 > int64(applicants * posts): return -1
  let edges = int(e64)
  if int64(length) != int64(3 + 3 * edges): return -1
  let postCount = posts + applicants
  let nodeCount = applicants + postCount
  let outputBytes = 8 * (applicants + 1)
  var rank: array[MaxA, array[MaxP, int64]]
  var rankSeen: array[MaxA, array[MaxP + 1, bool]]
  var maxRank: array[MaxA, int]
  for edge in 0 ..< edges:
    let at = 3 + 3 * edge
    let av = input[at]
    let pv = input[at + 1]
    let rv = input[at + 2]
    if av < 0 or av >= a64 or pv < 0 or pv >= p64 or rv < 1 or rv > p64: return -1
    let a = int(av)
    let p = int(pv)
    let r = int(rv)
    if rank[a][p] != 0: return -1
    rank[a][p] = rv
    rankSeen[a][r] = true
    if r > maxRank[a]: maxRank[a] = r
  for a in 0 ..< applicants:
    if maxRank[a] == 0: return -1
    for r in 1 .. maxRank[a]:
      if not rankSeen[a][r]: return -1

  var bestM1: array[MaxA, int]
  var bestM1Size = -1
  var m1Limit = 1
  for _ in 0 ..< applicants: m1Limit *= posts + 1
  for code in 0 ..< m1Limit:
    var value = code
    var candidate: array[MaxA, int]
    var used = 0
    var count = 0
    var valid = true
    for a in 0 ..< applicants:
      let p = value mod (posts + 1)
      value = value div (posts + 1)
      candidate[a] = p
      if p == posts: continue
      if rank[a][p] != 1 or (used and (1 shl p)) != 0:
        valid = false
        break
      used = used or (1 shl p)
      inc count
    if valid and (count > bestM1Size or (count == bestM1Size and lexLess(candidate, bestM1, applicants))):
      bestM1Size = count
      bestM1 = candidate

  var mateA: array[MaxA, int]
  var mateP: array[MaxP, int]
  for a in 0 ..< applicants: mateA[a] = -1
  for p in 0 ..< posts: mateP[p] = -1
  for a in 0 ..< applicants:
    if bestM1[a] < posts:
      mateA[a] = bestM1[a]
      mateP[bestM1[a]] = a
  var parity: array[MaxNodes, int]
  for n in 0 ..< nodeCount: parity[n] = -1
  var queue: array[MaxNodes, int]
  var head = 0
  var tail = 0
  for a in 0 ..< applicants:
    if mateA[a] < 0:
      parity[a] = 0
      queue[tail] = a
      inc tail
  for p in 0 ..< posts:
    if mateP[p] < 0:
      let node = applicants + p
      parity[node] = 0
      queue[tail] = node
      inc tail
  for p in posts ..< postCount:
    let node = applicants + p
    parity[node] = 0
    queue[tail] = node
    inc tail
  while head < tail:
    let node = queue[head]
    inc head
    if node < applicants:
      let a = node
      if parity[node] == 0:
        for p in 0 ..< posts:
          if rank[a][p] == 1 and mateA[a] != p and parity[applicants + p] < 0:
            parity[applicants + p] = 1
            queue[tail] = applicants + p
            inc tail
      elif mateA[a] >= 0 and parity[applicants + mateA[a]] < 0:
        parity[applicants + mateA[a]] = 0
        queue[tail] = applicants + mateA[a]
        inc tail
    else:
      let p = node - applicants
      if p < posts:
        if parity[node] == 0:
          for a in 0 ..< applicants:
            if rank[a][p] == 1 and mateA[a] != p and parity[a] < 0:
              parity[a] = 1
              queue[tail] = a
              inc tail
        elif mateP[p] >= 0 and parity[mateP[p]] < 0:
          parity[mateP[p]] = 0
          queue[tail] = mateP[p]
          inc tail
  var classOf: array[MaxNodes, int]
  for n in 0 ..< nodeCount: classOf[n] = (if parity[n] < 0: 2 else: parity[n])
  var reduced: array[MaxA, array[MaxPosts, bool]]
  var allowed: array[MaxA, array[MaxPosts, bool]]
  for a in 0 ..< applicants:
    var bestEvenRank = posts + 1
    for p in 0 ..< posts:
      if rank[a][p] == 1: reduced[a][p] = true
      if rank[a][p] > 0 and classOf[applicants + p] == 0 and int(rank[a][p]) < bestEvenRank:
        bestEvenRank = int(rank[a][p])
    let lastRank = maxRank[a] + 1
    if classOf[applicants + posts + a] == 0 and lastRank < bestEvenRank: bestEvenRank = lastRank
    for p in 0 ..< posts:
      if rank[a][p] > 0 and int(rank[a][p]) == bestEvenRank and classOf[applicants + p] == 0:
        reduced[a][p] = true
    if lastRank == bestEvenRank and classOf[applicants + posts + a] == 0:
      reduced[a][posts + a] = true
    for p in 0 ..< postCount:
      let ca = classOf[a]
      let cp = classOf[applicants + p]
      if reduced[a][p] and not ((ca == 1 and (cp == 1 or cp == 2)) or (ca == 2 and cp == 1)):
        allowed[a][p] = true

  var best: array[MaxA, int]
  var found = false
  var fullLimit = 1
  for _ in 0 ..< applicants: fullLimit *= postCount
  for code in 0 ..< fullLimit:
    var value = code
    var candidate: array[MaxA, int]
    var used = 0
    var firstCount = 0
    var valid = true
    for a in 0 ..< applicants:
      let p = value mod postCount
      value = value div postCount
      candidate[a] = p
      if not allowed[a][p] or (used and (1 shl p)) != 0:
        valid = false
        break
      used = used or (1 shl p)
      if p < posts and rank[a][p] == 1: inc firstCount
    if valid and firstCount == bestM1Size and (not found or lexLess(candidate, best, applicants)):
      found = true
      best = candidate
  if output.isNil or capacity < csize_t(outputBytes): return -2
  var staged: array[MaxOutput, uint8]
  put64(addr staged[0], 0, if found: 1 else: 0)
  for a in 0 ..< applicants: put64(addr staged[0], 8 * (a + 1), if found: int64(best[a]) else: -1)
  for byte in 0 ..< outputBytes: output[byte] = staged[byte]
  int64(outputBytes)
