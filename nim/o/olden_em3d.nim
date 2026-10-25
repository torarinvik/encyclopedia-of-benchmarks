const MaxNodes = 8
const MaxDegree = 4

proc olden_em3d*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "olden_em3d".} =
  if input.isNil or inputLength < csize_t(2): return -1
  let requestedN = input[0]
  let requestedDegree = input[1]
  if requestedN != requestedN or requestedDegree != requestedDegree or requestedN < 1.0 or
      requestedN > float64(MaxNodes) or float64(int(requestedN)) != requestedN or requestedDegree < 1.0 or
      requestedDegree > float64(MaxDegree) or float64(int(requestedDegree)) != requestedDegree: return -1
  let n = int(requestedN)
  let degree = int(requestedDegree)
  let edges = n * degree
  if inputLength != csize_t(2 + 2*n + 4*edges): return -1
  var electric, magnetic: array[MaxNodes, float64]
  var offset = 2
  for i in 0 ..< n:
    if input[offset+i] != input[offset+i] or input[offset+i] < 0.0 or input[offset+i] > 1.0: return -1
    electric[i] = input[offset+i]
  offset += n
  for i in 0 ..< n:
    if input[offset+i] != input[offset+i] or input[offset+i] < 0.0 or input[offset+i] > 1.0: return -1
    magnetic[i] = input[offset+i]
  offset += n
  let eNeighbors = offset; offset += edges
  let eCoefficients = offset; offset += edges
  let hNeighbors = offset; offset += edges
  let hCoefficients = offset
  for i in 0 ..< edges:
    let en = input[eNeighbors+i]; let hn = input[hNeighbors+i]
    if en != en or en < 0.0 or en >= float64(n) or float64(int(en)) != en or hn != hn or hn < 0.0 or hn >= float64(n) or float64(int(hn)) != hn: return -1
    if input[eCoefficients+i] != input[eCoefficients+i] or input[eCoefficients+i] < 0.0 or input[eCoefficients+i] > 1.0 or input[hCoefficients+i] != input[hCoefficients+i] or input[hCoefficients+i] < 0.0 or input[hCoefficients+i] > 1.0: return -1
    let start = (i div degree) * degree
    for j in start ..< i:
      if input[eNeighbors+j] == en or input[hNeighbors+j] == hn: return -1
  if output.isNil or outputCapacity < csize_t(2*n): return -2
  for node in 0 ..< n:
    var current = electric[node]
    let base = node * degree
    for edge in 0 ..< degree:
      let coefficient = base + (edge and not 1)
      current -= input[eCoefficients+coefficient] * magnetic[int(input[eNeighbors+base+edge])]
    electric[node] = current
  for node in 0 ..< n:
    var current = magnetic[node]
    let base = node * degree
    for edge in 0 ..< degree:
      let coefficient = base + (edge and not 1)
      current -= input[hCoefficients+coefficient] * electric[int(input[hNeighbors+base+edge])]
    magnetic[node] = current
  for i in 0 ..< n: output[i] = electric[i]; output[n+i] = magnetic[i]
  int64(2*n)
