const MaxVertices = 256

proc visit(vertex, n: int, adjacency: ptr UncheckedArray[bool], seen: ptr UncheckedArray[bool]) =
  seen[vertex] = true
  for next in 0 ..< n:
    if adjacency[vertex * MaxVertices + next] and not seen[next]: visit(next, n, adjacency, seen)

proc connected_components*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "connected_components".} =
  if input.isNil or length < 2 or length > 1026 or input[0] < 0 or input[0] > MaxVertices or input[1] < 0 or input[1] > 512: return -1
  let n = int(input[0]); let m = int(input[1])
  if int(length) != 2 + 2 * m: return -1
  var adjacency: array[MaxVertices * MaxVertices, bool]
  for i in 0 ..< m:
    let u = input[2 + 2 * i]; let v = input[3 + 2 * i]
    if u < 1 or u > int64(n) or v < 1 or v > int64(n): return -1
    let a = int(u - 1); let b = int(v - 1)
    adjacency[a * MaxVertices + b] = true; adjacency[b * MaxVertices + a] = true
  var seen: array[MaxVertices, bool]
  var components = 0'i64
  for i in 0 ..< n:
    if not seen[i]:
      visit(i, n, addr adjacency[0], addr seen[0])
      inc components
  components
