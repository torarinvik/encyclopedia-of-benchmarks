## Clean-room bounded implementation of Mestre's strict weighted profile.
const MaxA = 4
const MaxJ = 5
const MaxN = 9
const MaxParseable = 31
const InfLabel = 1_000_000_000'i64

proc lambdaMin(a: int, target: int, row: array[MaxA, array[MaxN, int]],
               rowLength: array[MaxA, int], fCategory: array[MaxN, int],
               label: array[MaxN, int64]): int64 =
  var best = InfLabel
  for i in 0 ..< rowLength[a]:
    let job = row[a][i]
    if job == target: break
    if fCategory[job] >= 0 and label[job] < best: best = label[job]
  best

proc augment(a: int, edges: array[MaxA, array[2, int]],
             edgeCount: array[MaxA, int], owner: var array[MaxN, int],
             seen: var array[MaxN, bool]): bool =
  for i in 0 ..< edgeCount[a]:
    let job = edges[a][i]
    if seen[job]: continue
    seen[job] = true
    let previous = owner[job]
    if previous < 0 or augment(previous, edges, edgeCount, owner, seen):
      owner[job] = a
      return true
  false

proc solve(applicants, jobs: int, weights: array[MaxA, int64],
           lengths: array[MaxA, int], listed: array[MaxA, array[MaxJ, int]]): int64 =
  var row: array[MaxA, array[MaxN, int]]
  var rowLength: array[MaxA, int]
  for a in 0 ..< applicants:
    for i in 0 ..< lengths[a]:
      row[a][rowLength[a]] = listed[a][i]
      inc rowLength[a]
    row[a][rowLength[a]] = jobs + a
    inc rowLength[a]

  var categoryWeight: array[MaxA, int64]
  var categoryCount = 0
  for a in 0 ..< applicants:
    var found = false
    for c in 0 ..< categoryCount:
      if categoryWeight[c] == weights[a]: found = true
    if not found:
      categoryWeight[categoryCount] = weights[a]
      inc categoryCount
  for i in 0 ..< categoryCount:
    for j in i + 1 ..< categoryCount:
      if categoryWeight[j] > categoryWeight[i]: swap(categoryWeight[i], categoryWeight[j])
  var category: array[MaxA, int]
  for a in 0 ..< applicants:
    while categoryWeight[category[a]] != weights[a]: inc category[a]

  var first, second: array[MaxA, int]
  var fCategory: array[MaxN, int]
  var label: array[MaxN, int64]
  var higher: array[MaxN, bool]
  for p in 0 ..< MaxN:
    fCategory[p] = -1
    label[p] = InfLabel
  for c in 0 ..< categoryCount:
    for a in 0 ..< applicants:
      if category[a] == c:
        for i in 0 ..< rowLength[a]:
          let p = row[a][i]
          if not higher[p]:
            first[a] = p
            break
    for a in 0 ..< applicants:
      if category[a] == c:
        fCategory[first[a]] = c
        higher[first[a]] = true

  for a in 0 ..< applicants:
    second[a] = -1
    for i in 0 ..< rowLength[a]:
      let p = row[a][i]
      if fCategory[p] < 0 or fCategory[p] > category[a]:
        second[a] = p
        break

  var keepFirst, keepSecond: array[MaxA, bool]
  for a in 0 ..< applicants:
    keepFirst[a] = true
    keepSecond[a] = second[a] >= 0
  for c in 0 ..< categoryCount:
    let weight = categoryWeight[c]
    if c == 0:
      for a in 0 ..< applicants:
        if category[a] == c: label[first[a]] = weight
      continue
    for a in 0 ..< applicants:
      if category[a] == c and lambdaMin(a, first[a], row, rowLength, fCategory, label) < weight:
        return 0
    for p in 0 ..< MaxN:
      if fCategory[p] == c:
        var group: array[MaxA, int]
        var count = 0
        for a in 0 ..< applicants:
          if category[a] == c and first[a] == p:
            group[count] = a
            inc count
        if count == 1:
          let earlier = lambdaMin(group[0], p, row, rowLength, fCategory, label)
          label[p] = if earlier >= InfLabel: weight else: min(weight, earlier - weight)
        else:
          label[p] = weight
          for i in 0 ..< count:
            let a = group[i]
            if lambdaMin(a, p, row, rowLength, fCategory, label) < 2 * weight:
              keepFirst[a] = false
    for a in 0 ..< applicants:
      if category[a] == c and second[a] >= 0 and
          lambdaMin(a, second[a], row, rowLength, fCategory, label) < weight:
        keepSecond[a] = false

  var isFirst: array[MaxN, bool]
  for a in 0 ..< applicants: isFirst[first[a]] = true
  for p in 0 ..< MaxN:
    if isFirst[p]:
      var eligible = false
      for a in 0 ..< applicants:
        if first[a] == p and keepFirst[a]: eligible = true
      if not eligible: return 0
  var edges: array[MaxA, array[2, int]]
  var edgeCount: array[MaxA, int]
  for a in 0 ..< applicants:
    if keepFirst[a]:
      edges[a][edgeCount[a]] = first[a]
      inc edgeCount[a]
    if keepSecond[a] and second[a] >= 0 and not isFirst[second[a]]:
      edges[a][edgeCount[a]] = second[a]
      inc edgeCount[a]
    if edgeCount[a] == 0: return 0
  var owner: array[MaxN, int]
  for p in 0 ..< MaxN: owner[p] = -1
  for a in 0 ..< applicants:
    var seen: array[MaxN, bool]
    if not augment(a, edges, edgeCount, owner, seen): return 0
  1

proc mestre_strict_weighted_popular_matching*(input: ptr UncheckedArray[int64],
    length: csize_t): int64 {.cdecl, exportc: "mestre_strict_weighted_popular_matching".} =
  if input == nil or length < 2 or length > csize_t(MaxParseable): return -1
  let a64 = input[0]
  let j64 = input[1]
  if a64 < 1 or a64 > MaxA or j64 < 1 or j64 > MaxJ: return -1
  let applicants = int(a64)
  let jobs = int(j64)
  if length < csize_t(2 + 2 * applicants): return -1
  var weights: array[MaxA, int64]
  var lengths: array[MaxA, int]
  var total = 0
  for a in 0 ..< applicants:
    weights[a] = input[2 + a]
    let size = input[2 + applicants + a]
    if weights[a] < 1 or weights[a] > 1000 or size < 1 or size > j64: return -1
    lengths[a] = int(size)
    total += lengths[a]
  if length != csize_t(2 + 2 * applicants + total): return -1
  var listed: array[MaxA, array[MaxJ, int]]
  var cursor = 2 + 2 * applicants
  for a in 0 ..< applicants:
    for i in 0 ..< lengths[a]:
      let value = input[cursor]
      inc cursor
      if value < 0 or value >= j64: return -1
      for k in 0 ..< i:
        if listed[a][k] == int(value): return -1
      listed[a][i] = int(value)
  solve(applicants, jobs, weights, lengths, listed)
