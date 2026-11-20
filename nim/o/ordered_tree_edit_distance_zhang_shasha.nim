const MaxN = 8
const MaxLen = 35
const Inf = 1_000_000'i64

type
  Tree = object
    n: int
    labels: array[MaxN, int64]
    children: array[MaxN, array[MaxN, int]]
    childCount: array[MaxN, int]
  Post = object
    n: int
    labels: array[MaxN + 1, int64]
    leftmost: array[MaxN + 1, int]

proc postVisit(tree: Tree, vertex: int, post: var Post): int =
  var left = 0
  for k in 0 ..< tree.childCount[vertex]:
    let childLeft = postVisit(tree, tree.children[vertex][k], post)
    if k == 0: left = childLeft
  inc post.n
  let id = post.n
  post.labels[id] = tree.labels[vertex]
  post.leftmost[id] = (if left == 0: id else: left)
  post.leftmost[id]

proc readTree(values: ptr UncheckedArray[int64], position: var int, n: int): tuple[ok: bool, tree: Tree] =
  var tree: Tree
  tree.n = n
  for v in 0 ..< n:
    let label = values[position]
    inc position
    if label < 0 or label > 3: return (false, tree)
    tree.labels[v] = label
  var stack: array[MaxN, int]
  var top = 0
  for v in 0 ..< n:
    let parent = values[position]
    inc position
    if v == 0:
      if parent != -1: return (false, tree)
      stack[0] = 0
      continue
    if parent < 0 or parent >= int64(v): return (false, tree)
    while top >= 0 and stack[top] != int(parent): dec top
    if top < 0: return (false, tree)
    let p = int(parent)
    tree.children[p][tree.childCount[p]] = v
    inc tree.childCount[p]
    inc top
    stack[top] = v
  (true, tree)

proc distance(a, b: Tree): int64 =
  var pa, pb: Post
  discard postVisit(a, 0, pa)
  discard postVisit(b, 0, pb)
  var keyA, keyB: array[MaxN + 1, int]
  for i in 1 .. pa.n: keyA[pa.leftmost[i]] = i
  for j in 1 .. pb.n: keyB[pb.leftmost[j]] = j
  var td: array[MaxN + 1, array[MaxN + 1, int64]]
  for rootA in 1 .. pa.n:
    if keyA[pa.leftmost[rootA]] != rootA: continue
    for rootB in 1 .. pb.n:
      if keyB[pb.leftmost[rootB]] != rootB: continue
      let startA = pa.leftmost[rootA]
      let startB = pb.leftmost[rootB]
      var fd: array[MaxN + 1, array[MaxN + 1, int64]]
      for x in 0 .. MaxN:
        for y in 0 .. MaxN: fd[x][y] = Inf
      fd[startA - 1][startB - 1] = 0
      for x in startA .. rootA: fd[x][startB - 1] = fd[x - 1][startB - 1] + 1
      for y in startB .. rootB: fd[startA - 1][y] = fd[startA - 1][y - 1] + 1
      for x in startA .. rootA:
        for y in startB .. rootB:
          let del = fd[x - 1][y] + 1
          let ins = fd[x][y - 1] + 1
          if pa.leftmost[x] == startA and pb.leftmost[y] == startB:
            let rename = fd[x - 1][y - 1] + (if pa.labels[x] != pb.labels[y]: 1'i64 else: 0'i64)
            let best = min(del, min(ins, rename))
            fd[x][y] = best
            td[x][y] = best
          else:
            let join = fd[pa.leftmost[x] - 1][pb.leftmost[y] - 1] + td[x][y]
            fd[x][y] = min(del, min(ins, join))
  td[pa.n][pb.n]

proc solve(values: ptr UncheckedArray[int64], length: int): int64 =
  if length < 6 or length > MaxLen: return -1
  let n1v = values[0]
  let n2v = values[1]
  if n1v < 1 or n1v > int64(MaxN) or n2v < 1 or n2v > int64(MaxN): return -1
  let n1 = int(n1v)
  let n2 = int(n2v)
  if length != 2 + 2 * n1 + 2 * n2: return -1
  var position = 2
  let a = readTree(values, position, n1)
  if not a.ok: return -1
  let b = readTree(values, position, n2)
  if not b.ok: return -1
  distance(a.tree, b.tree)

proc ordered_tree_edit_distance_zhang_shasha(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "ordered_tree_edit_distance_zhang_shasha".} =
  if input == nil or length < 6 or length > csize_t(MaxLen): return -1
  solve(input, int(length))
