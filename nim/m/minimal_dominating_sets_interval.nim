proc intersects(s, e: array[12, int64], a, b: int): bool =
  s[a] <= e[b] and s[b] <= e[a]

proc minimal_dominating_sets_interval*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "minimal_dominating_sets_interval".} =
  const MaxN = 12
  if input == nil or length < 3 or length > 25: return -1
  let n64 = input[0]
  if n64 < 1 or n64 > MaxN or length != csize_t(1 + 2 * n64): return -1
  let n = int(n64)
  var s, e: array[MaxN, int64]
  var minEnd = high(int64); var maxStart = low(int64)
  for i in 0 ..< n:
    s[i] = input[1 + 2*i]; e[i] = input[2 + 2*i]
    if s[i] < -100 or s[i] > 100 or e[i] < -100 or e[i] > 100 or s[i] >= e[i]: return -1
    if i > 0 and s[i-1] >= s[i]: return -1
    minEnd = min(minEnd, e[i]); maxStart = max(maxStart, s[i])
    for j in 0 ..< i:
      if s[i] == s[j] or s[i] == e[j] or e[i] == s[j] or e[i] == e[j]: return -1
  if output == nil or outputCapacity < 8: return -2
  var hasNext: array[MaxN, bool]
  var ncs, nce: array[MaxN, int64]
  var pSingle: array[MaxN, int64]
  for i in 0 ..< n:
    pSingle[i] = high(int64)
    for z in 0 ..< n:
      if intersects(s, e, i, z): pSingle[i] = min(pSingle[i], e[z])
      if s[z] > e[i]:
        if not hasNext[i] or s[z] < ncs[i]: ncs[i] = s[z]
        if not hasNext[i] or e[z] < nce[i]: nce[i] = e[z]
        hasNext[i] = true
  var valid: array[MaxN, array[MaxN, bool]]
  var pPair: array[MaxN, array[MaxN, int64]]
  for i in 0 ..< n:
    for j in i+1 ..< n:
      pPair[i][j] = high(int64)
      for z in 0 ..< n:
        if intersects(s, e, j, z) and not intersects(s, e, i, z): pPair[i][j] = min(pPair[i][j], e[z])
      valid[i][j] = hasNext[i] and pSingle[i] < s[j] and s[j] <= nce[i] and e[j] >= ncs[i]
  var ways: array[MaxN, array[MaxN, int64]]
  for j in 1 ..< n:
    for i in 0 ..< j:
      if not valid[i][j]: continue
      if s[i] <= minEnd: inc ways[i][j]
      for k in j+1 ..< n:
        if valid[j][k] and pPair[i][j] < s[k] and s[k] <= nce[j]: ways[j][k] += ways[i][j]
  var count = 0'i64
  for i in 0 ..< n:
    if s[i] <= minEnd and e[i] >= maxStart: inc count
  for i in 0 ..< n:
    for j in i+1 ..< n:
      if e[j] >= maxStart: count += ways[i][j]
  let bits = uint64(count)
  for b in 0 ..< 8: output[b] = uint8((bits shr (8*b)) and 0xff'u64)
  8
