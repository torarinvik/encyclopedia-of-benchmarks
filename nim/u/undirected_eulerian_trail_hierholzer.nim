proc undirected_eulerian_trail_hierholzer*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "undirected_eulerian_trail_hierholzer".} =
  if input == nil or length < 2 or length > 67: return -1
  if input[0] < 1 or input[0] > 16 or input[1] < 0 or input[1] > 32: return -1
  let n = int(input[0]); let m = int(input[1])
  if int(length) != 2 + 2 * m: return -1
  var endpoints: array[32, array[2, int]]
  var adjacency: array[16, array[64, int]]
  var degree, cursor: array[16, int]
  for e in 0 ..< m:
    let u0 = input[2 + 2 * e]; let v0 = input[3 + 2 * e]
    if u0 < 0 or v0 < 0 or u0 >= int64(n) or v0 >= int64(n): return -1
    let u = int(u0); let v = int(v0)
    endpoints[e] = [u, v]
    adjacency[u][degree[u]] = e; inc degree[u]
    adjacency[v][degree[v]] = e; inc degree[v]
  var odd = 0; var start = 0
  for v in 0 ..< n:
    if degree[v] mod 2 != 0:
      if odd == 0: start = v
      inc odd
  if odd != 0 and odd != 2: return 0
  if odd == 0 and m != 0:
    while degree[start] == 0: inc start
  var used: array[32, bool]
  var stack, reverse: array[33, int]
  var top = 1; var count = 0; stack[0] = start
  while top != 0:
    let v = stack[top - 1]
    while cursor[v] < degree[v] and used[adjacency[v][cursor[v]]]: inc cursor[v]
    if cursor[v] == degree[v]:
      dec top; reverse[count] = stack[top]; inc count
    else:
      let e = adjacency[v][cursor[v]]; inc cursor[v]; used[e] = true
      stack[top] = (if endpoints[e][0] == v: endpoints[e][1] else: endpoints[e][0])
      inc top
  if count != m + 1: return 0
  let bytes = count * 8
  if output == nil or capacity < csize_t(bytes): return -2
  for i in 0 ..< count:
    let value = uint64(reverse[count - 1 - i])
    for b in 0 ..< 8: output[i * 8 + b] = uint8((value shr (8 * b)) and 255)
  return int64(bytes)
