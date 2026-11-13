proc root(parent: array[8, int], vertex: int): int =
  result = vertex
  while parent[result] != result: result = parent[result]

proc karger_contraction_trial*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "karger_contraction_trial".} =
  if input == nil or length < 2 or length > 57: return -1
  if input[0] < 2 or input[0] > 8 or input[1] < 1 or input[1] > 24: return -1
  let n = int(input[0])
  let m = int(input[1])
  if length != csize_t(2 + 2 * m + n - 2): return -1
  var lefts, rights: array[24, int]
  var parent: array[8, int]
  for i in 0 ..< n: parent[i] = i
  for i in 0 ..< m:
    let a = input[2 + 2 * i]
    let b = input[3 + 2 * i]
    if a < 0 or b < 0 or a >= int64(n) or b >= int64(n) or a == b: return -1
    lefts[i] = int(a)
    rights[i] = int(b)
    let left = root(parent, lefts[i])
    let right = root(parent, rights[i])
    parent[left] = right
  let initial = root(parent, 0)
  for i in 1 ..< n:
    if root(parent, i) != initial: return -1
  for i in 0 ..< n: parent[i] = i
  for step in 0 ..< n - 2:
    var live = 0
    for i in 0 ..< m:
      if root(parent, lefts[i]) != root(parent, rights[i]): inc live
    var rank = input[2 + 2 * m + step]
    if rank < 0 or rank >= int64(live): return -1
    for i in 0 ..< m:
      let left = root(parent, lefts[i])
      let right = root(parent, rights[i])
      if left == right: continue
      if rank == 0:
        parent[left] = right
        break
      dec rank
  var cut = 0'i64
  for i in 0 ..< m:
    if root(parent, lefts[i]) != root(parent, rights[i]): inc cut
  cut
