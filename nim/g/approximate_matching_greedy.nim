type Edge = object
  u, v: int
  weight: int64
  used: bool

proc putI64(output: ptr UncheckedArray[uint8], word: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8: output[word * 8 + b] = uint8((bits shr (8*b)) and 255)

proc approximate_matching_greedy*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "approximate_matching_greedy".} =
  if input.isNil or length < 2 or length > 98: return -1
  let n0 = input[0]; let m0 = input[1]
  if n0 < 1 or n0 > 12 or m0 < 0 or m0 > 32 or int(length) != 2 + 3*int(m0): return -1
  let m = int(m0)
  var seen: array[12, array[12, bool]]
  var matched: array[12, bool]
  var edges: array[32, Edge]
  for i in 0 ..< m:
    let u0 = input[2+3*i]; let v0 = input[3+3*i]; let weight = input[4+3*i]
    if u0 < 0 or u0 >= n0 or v0 < 0 or v0 >= n0 or u0 == v0 or weight < 1 or weight > 100: return -1
    let u = int(u0); let v = int(v0)
    let lo = min(u, v); let hi = max(u, v)
    if seen[lo][hi]: return -1
    seen[lo][hi] = true; edges[i] = Edge(u: u, v: v, weight: weight, used: false)
  if output.isNil or capacity < 16: return -2
  var total = 0'i64; var selected = 0'u64
  for step in 0 ..< m:
    var best = m
    for i in 0 ..< m:
      if not edges[i].used and (best == m or edges[i].weight > edges[best].weight): best = i
    edges[best].used = true
    let edge = edges[best]
    if not matched[edge.u] and not matched[edge.v]:
      matched[edge.u] = true; matched[edge.v] = true
      selected = selected or (1'u64 shl best); total += edge.weight
  putI64(output, 0, total); putI64(output, 1, cast[int64](selected))
  16
