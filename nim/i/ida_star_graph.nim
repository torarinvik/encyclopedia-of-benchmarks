type Search = object
  n, goal, bound, nextBound: int
  h: array[12, int]
  edges: array[12, uint16]

proc visit(s: var Search, u, depth: int, path: uint16): int =
  let score = depth + s.h[u]
  if score > s.bound:
    s.nextBound = min(s.nextBound, score)
    return -1
  if u == s.goal: return depth
  for v in 0 ..< s.n:
    let bit = 1'u16 shl v
    if (s.edges[u] and bit) != 0 and (path and bit) == 0:
      let found = visit(s, v, depth + 1, path or bit)
      if found >= 0: return found
  return -1

proc ida_star_graph*(values: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc.} =
  if values == nil or length < 5 or length > 112: return low(int64)
  let n = values[0]
  let m = values[1]
  let start = values[2]
  let goal = values[3]
  if n < 1 or n > 12 or m < 0 or m > 48 or start < 0 or start >= n or
      goal < 0 or goal >= n or length != csize_t(4+n+2*m): return low(int64)
  var s: Search
  s.n = int(n); s.goal = int(goal)
  for i in 0 ..< s.n:
    if values[4+i] < 0 or values[4+i] >= n: return low(int64)
    s.h[i] = int(values[4+i])
  if s.h[s.goal] != 0: return low(int64)
  for i in 0 ..< int(m):
    let u = values[4+s.n+2*i]
    let v = values[5+s.n+2*i]
    if u < 0 or u >= n or v < 0 or v >= n or u == v: return low(int64)
    let bit = 1'u16 shl int(v)
    if (s.edges[int(u)] and bit) != 0 or s.h[int(u)] > s.h[int(v)] + 1: return low(int64)
    s.edges[int(u)] = s.edges[int(u)] or bit
  s.bound = s.h[int(start)]
  while true:
    s.nextBound = 1000
    let found = visit(s, int(start), 0, 1'u16 shl int(start))
    if found >= 0: return int64(found)
    if s.nextBound == 1000: return -1
    s.bound = s.nextBound
