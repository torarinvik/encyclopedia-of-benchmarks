const MaxVertices = 8
const MaxEdges = 28
const MaxInputWords = 59
const MaxOutputWords = 10

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc bondy_chvatal_hamiltonian_closure*(input: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "bondy_chvatal_hamiltonian_closure".} =
  if input == nil or length < 2 or length > MaxInputWords: return -1
  let nValue = input[0]
  let mValue = input[1]
  if nValue < 3 or nValue > MaxVertices or mValue < 0 or mValue > MaxEdges: return -1
  let n = int(nValue)
  let m = int(mValue)
  if m > n * (n - 1) div 2 or int(length) != 2 + 2 * m: return -1

  var adjacency: array[MaxVertices, array[MaxVertices, bool]]
  for edge in 0 ..< m:
    let uValue = input[2 + 2 * edge]
    let vValue = input[3 + 2 * edge]
    if uValue < 0 or uValue >= nValue or vValue < 0 or vValue >= nValue or uValue == vValue: return -1
    let u = int(uValue)
    let v = int(vValue)
    if adjacency[u][v]: return -1
    adjacency[u][v] = true
    adjacency[v][u] = true

  var added = 0
  while true:
    var degree: array[MaxVertices, int]
    for u in 0 ..< n:
      for v in 0 ..< n:
        if adjacency[u][v]: inc degree[u]
    var chosenU = n
    var chosenV = n
    for u in 0 ..< n:
      if chosenU < n: break
      for v in u + 1 ..< n:
        if not adjacency[u][v] and degree[u] + degree[v] >= n:
          chosenU = u
          chosenV = v
          break
    if chosenU == n: break
    adjacency[chosenU][chosenV] = true
    adjacency[chosenV][chosenU] = true
    inc added

  var staged: array[MaxOutputWords, int64]
  let fullMask = (1 shl n) - 1
  var complete = true
  for u in 0 ..< n:
    var row = 0
    for v in 0 ..< n:
      if adjacency[u][v]: row = row or (1 shl v)
    staged[2 + u] = int64(row)
    if row != (fullMask xor (1 shl u)): complete = false
  if complete: staged[0] = 1
  staged[1] = int64(added)

  let outputBytes = (2 + n) * 8
  if output == nil or capacity < csize_t(outputBytes): return -2
  for word in 0 ..< 2 + n: storeI64Le(output, word * 8, staged[word])
  int64(outputBytes)
