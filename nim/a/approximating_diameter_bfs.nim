proc putI64(output: ptr UncheckedArray[uint8], value: int64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8: output[b] = uint8((bits shr (8*b)) and 255)

proc approximating_diameter_bfs*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "approximating_diameter_bfs".} =
  if input.isNil or length < 2 or length > 242: return -1
  let n0 = input[0]; let m0 = input[1]
  if n0 < 1 or n0 > 16 or m0 < 0 or m0 > 120 or int(length) != 2 + 2*int(m0): return -1
  let n = int(n0); let m = int(m0)
  var adj: array[16, array[16, bool]]
  for i in 0 ..< m:
    let u0 = input[2+2*i]; let v0 = input[3+2*i]
    if u0 < 0 or v0 <= u0 or v0 >= n0: return -1
    let u = int(u0); let v = int(v0)
    if adj[u][v]: return -1
    adj[u][v] = true; adj[v][u] = true
  var dist: array[16, int64]
  var queue: array[16, int]
  for i in 0 ..< n: dist[i] = -1
  dist[0] = 0; queue[0] = 0
  var head = 0; var tail = 1
  while head < tail:
    let u = queue[head]; inc head
    for v in 0 ..< n:
      if adj[u][v] and dist[v] < 0:
        dist[v] = dist[u] + 1; queue[tail] = v; inc tail
  if tail != n: return -1
  var estimate = 0'i64
  for i in 0 ..< n:
    if dist[i] > estimate: estimate = dist[i]
  if output.isNil or capacity < 8: return -2
  putI64(output, estimate)
  8
