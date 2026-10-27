const MaxN = 12
const MaxInput = 26
const MaxQ = 576

proc storeI64LE(outp: ptr UncheckedArray[uint8], off: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0..<8: outp[off + b] = uint8((bits shr (8 * b)) and 255)

proc knapsack_profit_scaling_fptas*(input: ptr UncheckedArray[int64], length: csize_t,
                                    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "knapsack_profit_scaling_fptas".} =
  if input.isNil or length < 4 or length > csize_t(MaxInput): return -1
  let cap = input[0]; let n64 = input[1]
  if cap < 1 or cap > 100 or n64 < 1 or n64 > MaxN or length != csize_t(2 + 2 * int(n64)): return -1
  let n = int(n64)
  var weights: array[MaxN, int64]
  var profits: array[MaxN, int64]
  for i in 0..<n:
    weights[i] = input[2 + 2 * i]; profits[i] = input[3 + 2 * i]
    if weights[i] < 1 or weights[i] > 100 or profits[i] < 1 or profits[i] > 10000: return -1
  if output.isNil or capacity < csize_t(16): return -2
  var order: array[MaxN, int]
  var eligible = 0
  for i in 0..<n:
    if weights[i] <= cap: order[eligible] = i; inc eligible
  for i in 1..<eligible:
    let key = order[i]
    var j = i
    while j > 0 and profits[key] * weights[order[j - 1]] > profits[order[j - 1]] * weights[key]:
      order[j] = order[j - 1]; dec j
    order[j] = key
  var upper = 0'i64
  var room = cap
  for k in 0..<eligible:
    let i = order[k]
    if weights[i] <= room: upper += profits[i]; room -= weights[i]
    else: upper += profits[i] * room div weights[i]; break
  var dpWeight: array[MaxQ + 1, int64]
  var dpMask: array[MaxQ + 1, int64]
  for q in 0..MaxQ: dpWeight[q] = cap + 1
  dpWeight[0] = 0
  var reachable = 0
  for i in 0..<n:
    if weights[i] > cap or upper == 0: continue
    let value = int(4 * int64(n) * profits[i] div upper)
    if value == 0: continue
    var q = reachable
    while q >= 0:
      if dpWeight[q] <= cap:
        let next = q + value
        let nw = dpWeight[q] + weights[i]
        let nm = dpMask[q] or (1'i64 shl i)
        if nw < dpWeight[next] or (nw == dpWeight[next] and nm < dpMask[next]):
          dpWeight[next] = nw; dpMask[next] = nm
      dec q
    reachable += value
  var best = 0
  for q in 1..MaxQ:
    if dpWeight[q] <= cap: best = q
  let mask = dpMask[best]
  var selectedProfit = 0'i64
  for i in 0..<n:
    if ((cast[uint64](mask) shr i) and 1) != 0: selectedProfit += profits[i]
  storeI64LE(output, 0, mask); storeI64LE(output, 8, selectedProfit)
  16
