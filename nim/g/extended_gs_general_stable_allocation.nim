## Bounded Extended-GS for concave multi-unit stable allocations.
const MaxInput = 19
const MaxOutputBytes = 104
const Inf = 255'i64

proc utility(first, second, count: int64): int64 =
  if count == 0: return 0
  if count == 1: return first
  first + second

proc chooseMen(men, women, quota, edges: int, mf, ms, lower, upper: array[4, int64]): array[4, int64] =
  var answer: array[4, int64]
  var bestValue = -1'i64
  var codes = 1
  for edge in 0 ..< edges: codes *= 3
  for code in 0 ..< codes:
    var candidate: array[4, int64]
    var remainder = code
    for edge in countdown(edges - 1, 0):
      candidate[edge] = int64(remainder mod 3)
      remainder = remainder div 3
    var feasible = true
    for edge in 0 ..< edges:
      if candidate[edge] < lower[edge] or candidate[edge] > upper[edge]: feasible = false
    for man in 0 ..< men:
      var total = 0'i64
      for woman in 0 ..< women: total += candidate[man * women + woman]
      if total > int64(quota): feasible = false
    if not feasible: continue
    var value = 0'i64
    for edge in 0 ..< edges: value += utility(mf[edge], ms[edge], candidate[edge])
    if value > bestValue:
      bestValue = value
      for edge in 0 ..< edges: answer[edge] = candidate[edge]
  answer

proc chooseWomen(men, women, quota, edges: int, wf, ws, upper: array[4, int64]): array[4, int64] =
  var answer: array[4, int64]
  var bestValue = -1'i64
  var codes = 1
  for edge in 0 ..< edges: codes *= 3
  for code in 0 ..< codes:
    var candidate: array[4, int64]
    var remainder = code
    for edge in countdown(edges - 1, 0):
      candidate[edge] = int64(remainder mod 3)
      remainder = remainder div 3
    var feasible = true
    for edge in 0 ..< edges:
      if candidate[edge] > upper[edge]: feasible = false
    for woman in 0 ..< women:
      var total = 0'i64
      for man in 0 ..< men: total += candidate[man * women + woman]
      if total > int64(quota): feasible = false
    if not feasible: continue
    var value = 0'i64
    for edge in 0 ..< edges: value += utility(wf[edge], ws[edge], candidate[edge])
    if value > bestValue:
      bestValue = value
      for edge in 0 ..< edges: answer[edge] = candidate[edge]
  answer

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc extended_gs_general_stable_allocation*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "extended_gs_general_stable_allocation".} =
  if input.isNil or length < csize_t(3) or length > csize_t(MaxInput): return -1
  let menRaw = input[0]
  let womenRaw = input[1]
  let quotaRaw = input[2]
  if menRaw < 1 or menRaw > 2 or womenRaw < 1 or womenRaw > 2 or quotaRaw < 1 or quotaRaw > 2: return -1
  let men = int(menRaw)
  let women = int(womenRaw)
  let quota = int(quotaRaw)
  let edges = men * women
  if int(length) != 3 + 4 * edges: return -1
  var mf, ms, wf, ws: array[4, int64]
  for edge in 0 ..< edges:
    mf[edge] = input[3 + 4 * edge]; ms[edge] = input[4 + 4 * edge]
    wf[edge] = input[5 + 4 * edge]; ws[edge] = input[6 + 4 * edge]
    if mf[edge] < 0 or mf[edge] > 8 or ms[edge] < 0 or ms[edge] > mf[edge]
        or wf[edge] < 0 or wf[edge] > 8 or ws[edge] < 0 or ws[edge] > wf[edge]: return -1
  var xW, zW, xM, nextW: array[4, int64]
  var zM: array[4, int64]
  for edge in 0 ..< edges: zM[edge] = Inf
  var converged = false
  for iteration in 0 ..< 3 * edges + 2:
    xM = chooseMen(men, women, quota, edges, mf, ms, xW, zM)
    nextW = chooseWomen(men, women, quota, edges, wf, ws, xM)
    converged = true
    for edge in 0 ..< edges:
      if xM[edge] != nextW[edge]: converged = false
    if converged: break
    for edge in 0 ..< edges:
      if xM[edge] > nextW[edge]:
        zM[edge] = nextW[edge]
        zW[edge] = Inf
      xW[edge] = nextW[edge]
  if not converged: return -1
  let outputValues = 1 + 3 * edges
  let outputBytes = outputValues * 8
  if output.isNil or capacity < csize_t(outputBytes): return -2
  var staged: array[MaxOutputBytes, uint8]
  storeI64Le(addr staged[0], 0, int64(edges))
  for edge in 0 ..< edges:
    storeI64Le(addr staged[0], 8 * (1 + edge), xM[edge])
    storeI64Le(addr staged[0], 8 * (1 + edges + edge), zM[edge])
    storeI64Le(addr staged[0], 8 * (1 + 2 * edges + edge), max(zW[edge], xM[edge]))
  for byte in 0 ..< outputBytes: output[byte] = staged[byte]
  int64(outputBytes)
