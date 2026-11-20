const MaxN = 4
const MaxF = 3
const MaxQ = 4
const MaxP = 7
const NegInf = low(int64) div 4

proc putWord(output: ptr UncheckedArray[uint8], at: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8:
    output[at + b] = uint8((bits shr (8 * b)) and 255'u64)

proc capacitated_facility_location_t_hunt*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "capacitated_facility_location_t_hunt".} =
  if input == nil or length < 4 or length > 68: return -1
  let nr = input[0]
  let fr = input[1]
  let qr = input[2]
  let tr = input[3]
  if nr < 1 or nr > MaxN or fr < 1 or fr > MaxF or qr < 1 or qr > MaxQ or tr < 0 or tr >= fr: return -1
  let n = int(nr)
  let f = int(fr)
  let q = int(qr)
  let target = int(tr)
  let points = n + f
  if length != csize_t(4 + points * points + 2 * f + q + n): return -1
  var d: array[MaxP, array[MaxP, int64]]
  var fee: array[MaxF, int64]
  var caps: array[MaxF, int64]
  var kind: array[MaxQ, int]
  var assigned: array[MaxN, int]
  var at = 4
  for i in 0 ..< points:
    for j in 0 ..< points:
      let value = input[at]
      inc at
      if value < 0 or value > 1000: return -1
      d[i][j] = value
  for i in 0 ..< points:
    if d[i][i] != 0: return -1
    for j in 0 ..< points:
      if i != j and d[i][j] == 0: return -1
      if d[i][j] != d[j][i]: return -1
      for k in 0 ..< points:
        if d[i][j] > d[i][k] + d[k][j]: return -1
  for i in 0 ..< f:
    fee[i] = input[at]
    inc at
    if fee[i] < 0 or fee[i] > 1000: return -1
  for i in 0 ..< f:
    caps[i] = input[at]
    inc at
    if caps[i] < 1 or caps[i] > nr: return -1
  for i in 0 ..< q:
    let value = input[at]
    inc at
    if value < 0 or value >= fr: return -1
    kind[i] = int(value)
  for i in 0 ..< n:
    let value = input[at]
    inc at
    if value < 0 or value >= qr: return -1
    assigned[i] = int(value)

  var weight: array[MaxQ, int64]
  var profit: array[MaxQ, int64]
  var oldCost = 0'i64
  for c in 0 ..< q:
    profit[c] = fee[kind[c]]
    oldCost += fee[kind[c]]
  for u in 0 ..< n:
    let c = assigned[u]
    let source = kind[c]
    inc weight[c]
    if weight[c] > caps[source]: return -1
    let before = d[u][n + source]
    let after = d[u][n + target]
    oldCost += before
    profit[c] -= after - before

  var result: array[5, int64] = [0'i64, 0, 0, oldCost, oldCost]
  for copies in 1 .. n:
    let limit = min(n, copies * int(caps[target]))
    var dp: array[MaxN + 1, int64]
    var masks: array[MaxN + 1, uint32]
    for w in 0 .. MaxN: dp[w] = NegInf
    dp[0] = 0
    for item in 0 ..< q:
      var next = dp
      var nextMasks = masks
      let iw = int(weight[item])
      if iw <= limit:
        for w in 0 .. limit - iw:
          if dp[w] != NegInf:
            let nw = w + iw
            let value = dp[w] + profit[item]
            let mask = masks[w] or (1'u32 shl item)
            if value > next[nw] or (value == next[nw] and mask < nextMasks[nw]):
              next[nw] = value
              nextMasks[nw] = mask
      dp = next
      masks = nextMasks
    var best = NegInf
    var bestMask = 0'u32
    for w in 0 .. limit:
      if dp[w] > best or (dp[w] == best and masks[w] < bestMask):
        best = dp[w]
        bestMask = masks[w]
    if best > int64(copies) * fee[target]:
      result = [1'i64, int64(copies), int64(bestMask), oldCost,
                oldCost + int64(copies) * fee[target] - best]
      break
  if output == nil or capacity < 40: return -2
  for i in 0 ..< 5: putWord(output, 8 * i, result[i])
  return 40
