const MaxN = 8
const MaxM = 14
const MaxK = 5
const MaxInput = 50
const MaxMasks = 1 shl MaxK
const Inf = 1_000_000_000_000_000_000'i64

proc steiner_tree_subset_dp*(values: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "steiner_tree_subset_dp".} =
  if values.isNil or length < 3 or length > csize_t(MaxInput): return -1
  let n0 = values[0]
  let m0 = values[1]
  let k0 = values[2]
  if n0 < 1 or n0 > MaxN or m0 < 0 or m0 > MaxM or k0 < 1 or k0 > MaxK or k0 > n0: return -1
  let n = int(n0)
  let m = int(m0)
  let k = int(k0)
  if m > n * (n - 1) div 2 or length != csize_t(3 + k + 3 * m): return -1

  var terminalSeen: array[MaxN, bool]
  var terminals: array[MaxK, int]
  for i in 0 ..< k:
    let raw = values[3 + i]
    if raw < 0 or raw >= n0 or terminalSeen[int(raw)]: return -1
    terminalSeen[int(raw)] = true
    terminals[i] = int(raw)

  var present: array[MaxN * MaxN, bool]
  var weights: array[MaxN * MaxN, int64]
  for i in 0 ..< m:
    let u0 = values[3 + k + 3 * i]
    let v0 = values[4 + k + 3 * i]
    let w = values[5 + k + 3 * i]
    if u0 < 0 or u0 >= v0 or v0 >= n0 or w < 0 or w > 1000: return -1
    let u = int(u0)
    let v = int(v0)
    let edge = u * MaxN + v
    if present[edge]: return -1
    present[edge] = true
    present[v * MaxN + u] = true
    weights[edge] = w
    weights[v * MaxN + u] = w

  var dp: array[MaxMasks * MaxN, int64]
  for i in 0 ..< MaxMasks * MaxN: dp[i] = Inf
  for bit in 0 ..< k: dp[(1 shl bit) * MaxN + terminals[bit]] = 0
  let masks = 1 shl k
  for mask in 1 ..< masks:
    if (mask and (mask - 1)) != 0:
      var sub = (mask - 1) and mask
      while sub != 0:
        let other = mask xor sub
        if sub < other:
          for v in 0 ..< n:
            let left = dp[sub * MaxN + v]
            let right = dp[other * MaxN + v]
            if left < Inf and right < Inf and left + right < dp[mask * MaxN + v]:
              dp[mask * MaxN + v] = left + right
        sub = (sub - 1) and mask
    var used: array[MaxN, bool]
    for _ in 0 ..< n:
      var chosen = -1
      for v in 0 ..< n:
        if not used[v] and (chosen < 0 or dp[mask * MaxN + v] < dp[mask * MaxN + chosen]): chosen = v
      if chosen < 0 or dp[mask * MaxN + chosen] >= Inf: break
      used[chosen] = true
      for v in 0 ..< n:
        let edge = chosen * MaxN + v
        if present[edge] and not used[v]:
          let candidate = dp[mask * MaxN + chosen] + weights[edge]
          if candidate < dp[mask * MaxN + v]: dp[mask * MaxN + v] = candidate
  var answer = Inf
  for v in 0 ..< n: answer = min(answer, dp[(masks - 1) * MaxN + v])
  if answer >= Inf: return -2
  answer
