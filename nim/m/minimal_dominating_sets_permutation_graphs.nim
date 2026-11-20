const
  MaxN = 8
  MaxParseableLength = 10
  MaxStates = 59049
  Bottom = MaxN

type
  TopRanks = array[MaxN, int]
  Adjacency = array[MaxN, array[MaxN, bool]]
  Selected = array[5, int]

proc graphCase(top: TopRanks, i, j, k: int): int =
  let a = top[i]
  let b = top[j]
  let c = top[k]
  if a < b and b < c: return 1
  if a < c and c < b: return 2
  if b < a and a < c: return 3
  if b < c and c < a: return 4
  if c < a and a < b: return 5
  0

proc covered(adj: Adjacency, y: int, selected: Selected, count: int): bool =
  for z in 0 ..< count:
    if adj[selected[z]][y]: return true
  false

proc irredundant(adj: Adjacency, n: int, selected: Selected, count: int): bool =
  for x in 0 ..< count:
    var found = false
    for y in 0 ..< n:
      if not adj[selected[x]][y]: continue
      var shared = false
      for z in 0 ..< count:
        if z != x and adj[selected[z]][y]:
          shared = true
          break
      if not shared:
        found = true
        break
    if not found: return false
  true

proc privateMinRank(top: TopRanks, adj: Adjacency, n, x: int,
                    selected: Selected, count: int): int =
  var best = -1
  for y in 0 ..< n:
    if not adj[x][y]: continue
    var shared = false
    for z in 0 ..< count:
      if selected[z] != x and adj[selected[z]][y]:
        shared = true
        break
    if not shared and (best < 0 or top[y] < top[best]): best = y
  best

proc isInitial(top: TopRanks, adj: Adjacency, n, i, j, k, r, s: int): bool =
  var tri: Selected = [i, j, k, 0, 0]
  if r != n or not irredundant(adj, n, tri, 3): return false
  case graphCase(top, i, j, k)
  of 1:
    for y in 0 ..< n:
      if y < i and top[y] < top[i]: return false
    s == privateMinRank(top, adj, n, i, tri, 3)
  of 2:
    if s != n: return false
    for y in 0 ..< n:
      if top[y] < top[k] and y < j and not covered(adj, y, tri, 3): return false
    true
  of 3:
    for y in 0 ..< n:
      if top[y] < top[j] and y < i: return false
    s == privateMinRank(top, adj, n, j, tri, 3)
  of 4:
    if s != n: return false
    for y in 0 ..< n:
      if top[y] < top[j] and y < i and not covered(adj, y, tri, 3): return false
    true
  of 5:
    for y in 0 ..< n:
      if top[y] < top[k] and y < i: return false
    s == privateMinRank(top, adj, n, k, tri, 3)
  else: false

proc isRegular(top: TopRanks, adj: Adjacency, n, i, j, k, r, s: int): bool =
  let tri: Selected = [i, j, k, 0, 0]
  if not irredundant(adj, n, tri, 3): return false
  let kind = graphCase(top, i, j, k)
  if kind >= 1 and kind <= 4:
    if r < 0 or r >= i: return false
  elif kind == 5:
    if r != n: return false
  else: return false
  if kind == 2 or kind == 4: return s == n
  if s < 0 or s >= n: return false
  if kind == 1: return adj[i][s] and not adj[r][s] and not adj[j][s] and not adj[k][s]
  if kind == 3: return adj[j][s] and not adj[r][s] and not adj[i][s] and not adj[k][s]
  adj[k][s] and not adj[i][s] and not adj[j][s]

proc isFinal(top: TopRanks, adj: Adjacency, n, i, j, k, r: int): bool =
  var selected: Selected
  var count = 0
  if r != n:
    selected[count] = r
    inc count
  selected[count] = i; inc count
  selected[count] = j; inc count
  selected[count] = k; inc count
  for y in 0 ..< n:
    if i < y and top[i] < top[y] and not covered(adj, y, selected, count): return false
  true

proc stateIndex(i, j, k, r, s, base: int): int =
  ((((i * base + j) * base + k) * base + r) * base + s)

proc successor(top: TopRanks, topVertex: array[MaxN, int], adj: Adjacency,
               n, i, j, k, r, s, ell: int, outR, outS: var int): bool =
  let kind = graphCase(top, j, k, ell)
  if kind == 0: return false
  var selected: Selected
  var count = 0
  if r != n: selected[count] = r; inc count
  selected[count] = i; inc count
  selected[count] = j; inc count
  selected[count] = k; inc count
  selected[count] = ell; inc count
  if not irredundant(adj, n, selected, count): return false
  if s != n and top[ell] <= top[s]: return false
  if not adj[j][k]:
    for y in 0 ..< n:
      if i < y and y < j and top[i] < top[y] and top[y] < top[j] and
          not covered(adj, y, selected, count): return false
  if adj[i][k]:
    for y in 0 ..< n:
      if j < y and y < k and top[j] < top[y] and top[y] < top[ell] and
          not covered(adj, y, selected, count): return false
  if kind == 5: outR = n
  else:
    var maxRank = top[i]
    if r != n and top[r] > maxRank: maxRank = top[r]
    outR = topVertex[maxRank]
  if kind == 2 or kind == 4: outS = n
  else:
    let oldMin = min(top[i], min(top[j], top[k]))
    let newMin = min(top[j], min(top[k], top[ell]))
    if s != n and oldMin == newMin: outS = s
    else:
      var y = j
      if top[k] < top[y]: y = k
      if top[ell] < top[y]: y = ell
      outS = privateMinRank(top, adj, n, y, selected, count)
      if outS < 0: return false
  isRegular(top, adj, n, j, k, ell, outR, outS)

proc dominates(mask: uint32, hoods: array[MaxN, uint32], n: int): bool =
  var cover = 0'u32
  for x in 0 ..< n:
    if (mask and (1'u32 shl x)) != 0: cover = cover or hoods[x]
  cover == ((1'u32 shl n) - 1'u32)

proc solve(top: TopRanks, n: int): int64 =
  var adj: Adjacency
  var topVertex: array[MaxN, int]
  for x in 0 ..< n:
    topVertex[top[x]] = x
    adj[x][x] = true
  for x in 0 ..< n:
    for y in x + 1 ..< n:
      adj[x][y] = top[x] > top[y]
      adj[y][x] = adj[x][y]
  let base = n + 1
  var ways: array[MaxStates, int64]
  var answer = 0'i64
  for i in countdown(n - 3, 0):
    for j in i + 1 ..< n - 1:
      for k in j + 1 ..< n:
        var tri: Selected = [i, j, k, 0, 0]
        if graphCase(top, i, j, k) == 0 or not irredundant(adj, n, tri, 3): continue
        for ri in 0 .. i:
          let r = if ri == i: n else: ri
          for s in 0 .. n:
            if not isInitial(top, adj, n, i, j, k, r, s) and
                not isRegular(top, adj, n, i, j, k, r, s): continue
            var paths = if isFinal(top, adj, n, i, j, k, r): 1'i64 else: 0'i64
            for ell in k + 1 ..< n:
              var nr, ns: int
              if successor(top, topVertex, adj, n, i, j, k, r, s, ell, nr, ns):
                paths += ways[stateIndex(j, k, ell, nr, ns, base)]
            ways[stateIndex(i, j, k, r, s, base)] = paths
            if isInitial(top, adj, n, i, j, k, r, s): answer += paths
  var hoods: array[MaxN, uint32]
  for x in 0 ..< n:
    for y in 0 ..< n:
      if adj[x][y]: hoods[x] = hoods[x] or (1'u32 shl y)
  let full = (1'u32 shl n) - 1'u32
  for mask in 1'u32 .. full:
    var size = 0
    var bits = mask
    while bits != 0:
      size += int(bits and 1'u32)
      bits = bits shr 1
    if size > 2 or not dominates(mask, hoods, n): continue
    var minimal = true
    for x in 0 ..< n:
      let bit = 1'u32 shl x
      if (mask and bit) != 0 and dominates(mask xor bit, hoods, n): minimal = false
    if minimal: inc answer
  answer

proc minimal_dominating_sets_permutation_graphs*(input: ptr UncheckedArray[int64],
    length: csize_t): int64 {.cdecl, exportc: "minimal_dominating_sets_permutation_graphs".} =
  if input.isNil or length < 1 or length > csize_t(MaxParseableLength): return -1
  let rawN = input[0]
  if rawN < 1 or rawN > MaxN: return -1
  let n = int(rawN)
  if length != csize_t(n + 1): return -1
  var top: TopRanks
  var seen: array[MaxN, bool]
  for x in 0 ..< n:
    let rank = input[x + 1]
    if rank < 0 or rank >= rawN: return -1
    let ri = int(rank)
    if seen[ri]: return -1
    seen[ri] = true
    top[x] = ri
  solve(top, n)
