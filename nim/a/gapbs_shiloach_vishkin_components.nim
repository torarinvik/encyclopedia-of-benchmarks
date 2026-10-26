const MaxN = 16
const MaxM = 64

proc compressComponents(n: int, component: var array[MaxN, int]) =
  for node in 0..<n:
    while component[node] != component[component[node]]:
      component[node] = component[component[node]]

proc storeI64LE(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc gapbs_shiloach_vishkin_components*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "gapbs_shiloach_vishkin_components".} =
  if input.isNil or length < csize_t(2) or length > csize_t(2 + 2 * MaxM): return -1
  let n64 = input[0]
  let m64 = input[1]
  if n64 < 1 or n64 > int64(MaxN) or m64 < 0 or m64 > int64(MaxM) or
      int64(length) != 2 + 2 * m64: return -1
  let n = int(n64)
  let m = int(m64)
  var adjacency: array[MaxN * MaxN, bool]
  for edge in 0..<m:
    let pos = 2 + 2 * edge
    let u = input[pos]
    let v = input[pos + 1]
    if u < 0 or v <= u or v >= n64 or adjacency[int(u) * MaxN + int(v)]: return -1
    adjacency[int(u) * MaxN + int(v)] = true
    adjacency[int(v) * MaxN + int(u)] = true
  let outputBytes = 8 * n
  if output.isNil or capacity < csize_t(outputBytes): return -2
  var component: array[MaxN, int]
  for node in 0..<n: component[node] = node
  var changed = true
  var rounds = 0
  let roundLimit = n * n + 1
  while changed and rounds < roundLimit:
    changed = false
    for u in 0..<n:
      for v in 0..<n:
        if not adjacency[u * MaxN + v]: continue
        let componentU = component[u]
        let componentV = component[v]
        if componentU == componentV: continue
        let high = max(componentU, componentV)
        let low = min(componentU, componentV)
        if component[high] == high:
          changed = true
          component[high] = low
    compressComponents(n, component)
    inc rounds
  if changed: return -1
  for node in 0..<n: storeI64LE(output, 8 * node, int64(component[node]))
  int64(outputBytes)
