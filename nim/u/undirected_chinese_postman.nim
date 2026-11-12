const MaxN = 8
const MaxM = 12
const Inf = 1_000_000_000'i64

proc solve(input: ptr UncheckedArray[int64], length: csize_t): int64 =
  if input.isNil or length < csize_t(2) or length > csize_t(38): return -1
  if input[0] < 1 or input[0] > int64(MaxN) or input[1] < 0 or input[1] > int64(MaxM): return -1
  let n = int(input[0])
  let m = int(input[1])
  if length != csize_t(2 + 3 * m): return -1
  if n == 1: return if m == 0: 0 else: -1
  if m < n - 1: return -1
  var distance: array[MaxN * MaxN, int64]
  var seen: array[MaxN * MaxN, bool]
  var degree: array[MaxN, int]
  for u in 0 ..< n:
    for v in 0 ..< n:
      distance[u * MaxN + v] = if u == v: 0 else: Inf
  var totalWeight = 0'i64
  for edge in 0 ..< m:
    let uValue = input[2 + 3 * edge]
    let vValue = input[3 + 3 * edge]
    let weight = input[4 + 3 * edge]
    if uValue < 0 or uValue >= int64(n) or vValue < 0 or vValue >= int64(n) or
       uValue == vValue or weight < 1 or weight > 1000: return -1
    let u = int(uValue)
    let v = int(vValue)
    if seen[u * MaxN + v]: return -1
    seen[u * MaxN + v] = true
    seen[v * MaxN + u] = true
    distance[u * MaxN + v] = weight
    distance[v * MaxN + u] = weight
    degree[u] += 1
    degree[v] += 1
    totalWeight += weight
  for middle in 0 ..< n:
    for source in 0 ..< n:
      for target in 0 ..< n:
        let candidate = distance[source * MaxN + middle] + distance[middle * MaxN + target]
        if candidate < distance[source * MaxN + target]: distance[source * MaxN + target] = candidate
  for vertex in 0 ..< n:
    if distance[vertex] >= Inf: return -1
  var odd: array[MaxN, int]
  var oddCount = 0
  for vertex in 0 ..< n:
    if (degree[vertex] and 1) != 0:
      odd[oddCount] = vertex
      oddCount += 1
  let stateCount = 1 shl oddCount
  var pairing: array[1 shl MaxN, int64]
  for mask in 0 ..< stateCount: pairing[mask] = Inf
  pairing[0] = 0
  for mask in 1 ..< stateCount:
    var first = 0
    while (mask and (1 shl first)) == 0: first += 1
    let firstBit = 1 shl first
    for partner in first + 1 ..< oddCount:
      let partnerBit = 1 shl partner
      if (mask and partnerBit) == 0: continue
      let remaining = mask xor firstBit xor partnerBit
      let candidate = distance[odd[first] * MaxN + odd[partner]] + pairing[remaining]
      if candidate < pairing[mask]: pairing[mask] = candidate
  totalWeight + pairing[stateCount - 1]

proc undirected_chinese_postman*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "undirected_chinese_postman".} =
  solve(input, length)
