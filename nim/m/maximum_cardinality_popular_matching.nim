# Bounded clean-room strict-list maximum-cardinality popular matching.
const MaxA = 6
const MaxP = 6
const MaxParseable = 45

proc mpAugment(applicant, posts: int, first, second: array[MaxA, int],
               owner: var array[MaxP, int], assignment: var array[MaxA, int],
               seen: var array[MaxP, bool]): bool =
  var edges = [first[applicant], -1]
  var count = 1
  if second[applicant] < posts:
    edges[1] = second[applicant]
    count = 2
  if count == 2 and edges[1] < edges[0]: swap(edges[0], edges[1])
  for i in 0 ..< count:
    let post = edges[i]
    if seen[post]: continue
    seen[post] = true
    let previous = owner[post]
    if previous < 0 or mpAugment(previous, posts, first, second, owner, assignment, seen):
      owner[post] = applicant
      assignment[applicant] = post
      return true
  false

proc mpSolve(applicants, posts: int, preferences: array[MaxA, array[MaxP, int]],
             lengths: array[MaxA, int]): int64 =
  var first, second: array[MaxA, int]
  var firstPost: array[MaxP, bool]
  for a in 0 ..< applicants:
    first[a] = preferences[a][0]
    firstPost[first[a]] = true
  for a in 0 ..< applicants:
    second[a] = posts + a
    for j in 0 ..< lengths[a]:
      let candidate = preferences[a][j]
      if not firstPost[candidate]:
        second[a] = candidate
        break

  var activeA: array[MaxA, bool]
  var activeP: array[MaxP, bool]
  var assignment: array[MaxA, int]
  for a in 0 ..< applicants:
    activeA[a] = second[a] < posts
    assignment[a] = -1
  for p in 0 ..< posts: activeP[p] = true
  while true:
    var degree: array[MaxP, int]
    var sole: array[MaxP, int]
    for p in 0 ..< MaxP: sole[p] = -1
    for a in 0 ..< applicants:
      if activeA[a]:
        for post in [first[a], second[a]]:
          if activeP[post]:
            inc degree[post]
            sole[post] = a
    var forced = -1
    for p in 0 ..< posts:
      if activeP[p] and degree[p] == 1:
        forced = p
        break
    if forced < 0: break
    let a = sole[forced]
    assignment[a] = forced
    activeA[a] = false
    activeP[forced] = false

  var degree: array[MaxP, int]
  var neighbors: array[MaxP, array[2, int]]
  var neighborCount: array[MaxP, int]
  var activeCount = 0
  for a in 0 ..< applicants:
    if activeA[a]:
      inc activeCount
      for post in [first[a], second[a]]:
        if not activeP[post]: return 0
        if neighborCount[post] < 2:
          neighbors[post][neighborCount[post]] = a
        inc neighborCount[post]
        inc degree[post]
  var residualPosts = 0
  for p in 0 ..< posts:
    if activeP[p] and degree[p] > 0:
      inc residualPosts
      if degree[p] != 2 or neighborCount[p] != 2: return 0
  if residualPosts < activeCount or residualPosts != activeCount: return 0

  var visited: array[MaxA, bool]
  for root in 0 ..< applicants:
    if activeA[root] and not visited[root]:
      var currentPost = min(first[root], second[root])
      assignment[root] = currentPost
      visited[root] = true
      var currentA = root
      while true:
        let nextA = if neighbors[currentPost][0] != currentA:
          neighbors[currentPost][0] else: neighbors[currentPost][1]
        if nextA == root: break
        if visited[nextA]: return 0
        let nextPost = if first[nextA] == currentPost: second[nextA] else: first[nextA]
        assignment[nextA] = nextPost
        visited[nextA] = true
        currentA = nextA
        currentPost = nextPost

  var owner: array[MaxP, int]
  for p in 0 ..< MaxP: owner[p] = -1
  for a in 0 ..< applicants:
    if assignment[a] >= 0: owner[assignment[a]] = a
  for a in 0 ..< applicants:
    if second[a] >= posts and assignment[a] < 0:
      var seen: array[MaxP, bool]
      discard mpAugment(a, posts, first, second, owner, assignment, seen)
  for a in 0 ..< applicants:
    if assignment[a] < 0: assignment[a] = posts + a
  for p in 0 ..< posts:
    if firstPost[p] and owner[p] < 0:
      var a = 0
      while first[a] != p: inc a
      let old = assignment[a]
      if old < posts: owner[old] = -1
      assignment[a] = p
      owner[p] = a
  var result = 0
  for a in 0 ..< applicants:
    if assignment[a] < posts: inc result
  int64(result)

proc maximum_cardinality_popular_matching*(input: ptr UncheckedArray[int64],
    length: csize_t): int64 {.cdecl, exportc: "maximum_cardinality_popular_matching".} =
  if input == nil or length < 2 or length > csize_t(MaxParseable): return -1
  let a64 = input[0]
  let p64 = input[1]
  if a64 < 1 or a64 > MaxA or p64 < 1 or p64 > MaxP: return -1
  let applicants = int(a64)
  let posts = int(p64)
  if length < csize_t(2 + applicants): return -1
  var lengths: array[MaxA, int]
  var total = 0
  for a in 0 ..< applicants:
    let size = input[2 + a]
    if size < 1 or size > p64: return -1
    lengths[a] = int(size)
    total += lengths[a]
  if length != csize_t(2 + applicants + total): return -1
  var preferences: array[MaxA, array[MaxP, int]]
  var cursor = 2 + applicants
  for a in 0 ..< applicants:
    for j in 0 ..< lengths[a]:
      let value = input[cursor]
      inc cursor
      if value < 0 or value >= p64: return -1
      let post = int(value)
      for k in 0 ..< j:
        if preferences[a][k] == post: return -1
      preferences[a][j] = post
  mpSolve(applicants, posts, preferences, lengths)
