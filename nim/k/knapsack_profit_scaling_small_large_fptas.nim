const MaxN = 8
const MaxInput = 18
const MaxQ = 128

proc storeI64LE(outp: ptr UncheckedArray[uint8], off: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0..<8: outp[off + b] = uint8((bits shr (8 * b)) and 255)

proc knapsack_profit_scaling_small_large_fptas*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "knapsack_profit_scaling_small_large_fptas".} =
  if input.isNil or length < 4 or length > csize_t(MaxInput): return -1
  let cap = input[0]; let n64 = input[1]
  if cap < 1 or cap > 30 or n64 < 1 or n64 > MaxN or length != csize_t(2 + 2 * int(n64)): return -1
  let n = int(n64)
  var weights: array[MaxN, int64]; var profits: array[MaxN, int64]
  for i in 0..<n:
    weights[i] = input[2 + 2 * i]; profits[i] = input[3 + 2 * i]
    if weights[i] < 1 or weights[i] > 30 or profits[i] < 1 or profits[i] > 100: return -1
  if output.isNil or capacity < csize_t(16): return -2
  var order: array[MaxN, int]; var eligible = 0
  for i in 0..<n:
    if weights[i] <= cap: order[eligible] = i; inc eligible
  for i in 1..<eligible:
    let key = order[i]; var j = i
    while j > 0 and profits[key] * weights[order[j - 1]] > profits[order[j - 1]] * weights[key]: order[j] = order[j - 1]; dec j
    order[j] = key
  var upperNum = 0'i64; var upperDen = 1'i64; var room = cap
  for k in 0..<eligible:
    let i = order[k]
    if weights[i] <= room: upperNum += profits[i]; room -= weights[i]
    else: upperNum = upperNum * weights[i] + profits[i] * room; upperDen = weights[i]; break
  var small: array[MaxN, int]; var large: array[MaxN, int]; var ns = 0; var nl = 0
  for i in 0..<n:
    if weights[i] <= cap:
      if 4 * profits[i] * upperDen <= upperNum: small[ns] = i; inc ns
      else: large[nl] = i; inc nl
  for i in 1..<ns:
    let key = small[i]; var j = i
    while j > 0 and profits[key] * weights[small[j - 1]] > profits[small[j - 1]] * weights[key]: small[j] = small[j - 1]; dec j
    small[j] = key
  var dpWeight: array[MaxQ + 1, int64]; var dpMask: array[MaxQ + 1, int64]
  for q in 0..MaxQ: dpWeight[q] = cap + 1
  dpWeight[0] = 0; var reachable = 0
  for k in 0..<nl:
    let i = large[k]; let value = if upperNum > 0: int(16 * profits[i] * upperDen div upperNum) else: 0
    var q = reachable
    while q >= 0:
      if dpWeight[q] <= cap:
        let next = q + value; let nw = dpWeight[q] + weights[i]; let nm = dpMask[q] or (1'i64 shl i)
        if nw < dpWeight[next] or (nw == dpWeight[next] and nm < dpMask[next]): dpWeight[next] = nw; dpMask[next] = nm
      dec q
    reachable += value
  var bestMask = 0'i64; var bestProfit = 0'i64
  for q in 0..reachable:
    if dpWeight[q] <= cap:
      var mask = dpMask[q]; var value = 0'i64; var remaining = cap - dpWeight[q]
      for i in 0..<n:
        if ((cast[uint64](mask) shr i) and 1) != 0: value += profits[i]
      for k in 0..<ns:
        let i = small[k]
        if weights[i] <= remaining: remaining -= weights[i]; mask = mask or (1'i64 shl i); value += profits[i]
      if value > bestProfit or (value == bestProfit and mask < bestMask): bestProfit = value; bestMask = mask
  storeI64LE(output, 0, bestMask); storeI64LE(output, 8, bestProfit)
  16
