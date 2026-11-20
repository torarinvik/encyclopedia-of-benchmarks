const MaxA = 4
const MaxP = 4
const MaxV = 8
const MaxRank = 4
const MaxInput = 52
const MaxOutput = 40

proc put64(output: ptr UncheckedArray[uint8], at: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[at + byte] = uint8((bits shr (8 * byte)) and 255)

proc lexLess(left, right: array[MaxA, int], count: int): bool =
  for index in 0 ..< count:
    if left[index] != right[index]: return left[index] < right[index]
  false

proc rank_maximal_matching_irving*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "rank_maximal_matching_irving".} =
  if input.isNil or length < csize_t(3) or length > csize_t(MaxInput): return -1
  let a64, p64, e64 = input[0], input[1], input[2]
  if a64 < 1 or a64 > int64(MaxA) or p64 < 1 or p64 > int64(MaxP): return -1
  let applicants, posts = int(a64), int(p64)
  if e64 < a64 or e64 > int64(applicants * posts): return -1
  let edges = int(e64)
  if edges > 16 or int64(length) != int64(3 + 3 * edges): return -1

  var rank: array[MaxA, array[MaxP, int]]
  var degree: array[MaxA, int]
  var maxRank = 0
  for edge in 0 ..< edges:
    let at = 3 + 3 * edge
    let av, pv, rv = input[at], input[at + 1], input[at + 2]
    if av < 0 or av >= a64 or pv < 0 or pv >= p64 or rv < 1 or rv > int64(MaxRank): return -1
    let a, p, r = int(av), int(pv), int(rv)
    if rank[a][p] != 0: return -1
    rank[a][p] = r
    inc degree[a]
    if r > maxRank: maxRank = r
  for a in 0 ..< applicants:
    if degree[a] == 0: return -1

  var blocked: array[MaxA, array[MaxP, bool]]
  var mateA: array[MaxA, int]
  var mateP: array[MaxP, int]
  for a in 0 ..< MaxA: mateA[a] = -1
  for p in 0 ..< MaxP: mateP[p] = -1
  for phase in 1 .. maxRank:
    var limit = 1
    for _ in 0 ..< applicants: limit *= posts + 1
    var best: array[MaxA, int]
    var bestSize = -1
    for code in 0 ..< limit:
      var value = code
      var candidate: array[MaxA, int]
      var used = 0
      var size = 0
      var valid = true
      for a in 0 ..< applicants:
        let p = value mod (posts + 1)
        value = value div (posts + 1)
        candidate[a] = p
        if p == posts: continue
        if rank[a][p] == 0 or rank[a][p] > phase or blocked[a][p] or (used and (1 shl p)) != 0:
          valid = false
          break
        used = used or (1 shl p)
        inc size
      if valid and (size > bestSize or (size == bestSize and lexLess(candidate, best, applicants))):
        bestSize = size
        best = candidate
    for a in 0 ..< MaxA: mateA[a] = -1
    for p in 0 ..< MaxP: mateP[p] = -1
    for a in 0 ..< applicants:
      if best[a] < posts:
        mateA[a] = best[a]
        mateP[best[a]] = a

    var classes: array[MaxV, int]
    for v in 0 ..< applicants + posts: classes[v] = 2
    var queue: array[MaxV, int]
    var head, tail = 0
    for a in 0 ..< applicants:
      if mateA[a] < 0:
        classes[a] = 0
        queue[tail] = a
        inc tail
    for p in 0 ..< posts:
      if mateP[p] < 0:
        let v = applicants + p
        classes[v] = 0
        queue[tail] = v
        inc tail
    while head < tail:
      let v = queue[head]
      inc head
      if v < applicants:
        let a = v
        if classes[v] == 0:
          for p in 0 ..< posts:
            let w = applicants + p
            if rank[a][p] > 0 and rank[a][p] <= phase and not blocked[a][p] and mateA[a] != p and classes[w] == 2:
              classes[w] = 1
              queue[tail] = w
              inc tail
        elif mateA[a] >= 0:
          let w = applicants + mateA[a]
          if classes[w] == 2:
            classes[w] = 0
            queue[tail] = w
            inc tail
      else:
        let p = v - applicants
        if classes[v] == 0:
          for a in 0 ..< applicants:
            if rank[a][p] > 0 and rank[a][p] <= phase and not blocked[a][p] and mateA[a] != p and classes[a] == 2:
              classes[a] = 1
              queue[tail] = a
              inc tail
        elif mateP[p] >= 0 and classes[mateP[p]] == 2:
          classes[mateP[p]] = 0
          queue[tail] = mateP[p]
          inc tail
    for a in 0 ..< applicants:
      for p in 0 ..< posts:
        if rank[a][p] == 0 or blocked[a][p]: continue
        let ca, cp = classes[a], classes[applicants + p]
        if rank[a][p] <= phase:
          if (ca == 1 and cp != 0) or (cp == 1 and ca != 0): blocked[a][p] = true
        elif ca != 0 or cp != 0:
          blocked[a][p] = true

  var signature: array[MaxRank, int64]
  for a in 0 ..< applicants:
    if mateA[a] >= 0: inc signature[rank[a][mateA[a]] - 1]
  let outputBytes = 8 * (maxRank + 1)
  if output.isNil or capacity < csize_t(outputBytes): return -2
  var staged: array[MaxOutput, uint8]
  put64(addr staged[0], 0, int64(maxRank))
  for r in 0 ..< maxRank: put64(addr staged[0], 8 * (r + 1), signature[r])
  for byte in 0 ..< outputBytes: output[byte] = staged[byte]
  int64(outputBytes)
