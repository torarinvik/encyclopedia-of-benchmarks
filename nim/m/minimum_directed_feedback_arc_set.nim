const
  MaxN = 8
  MaxM = 56
  MaxLength = 114
  MaxStates = 256
  Inf = 2305843009213693951'i64

proc minimum_directed_feedback_arc_set*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "minimum_directed_feedback_arc_set".} =
  if input == nil or length < 2 or length > csize_t(MaxLength + 1): return -1
  if input[0] < 1 or input[0] > int64(MaxN) or input[1] < 0 or input[1] > int64(MaxM): return -1
  let n = int(input[0])
  let m = int(input[1])
  if int(length) != 2 + 2*m: return -1

  var outgoing: array[MaxN, int]
  for edge in 0 ..< m:
    let tailValue = input[2 + 2*edge]
    let headValue = input[3 + 2*edge]
    if tailValue < 0 or headValue < 0 or tailValue >= int64(n) or headValue >= int64(n) or tailValue == headValue:
      return -1
    let tail = int(tailValue)
    let head = int(headValue)
    let bit = 1 shl head
    if (outgoing[tail] and bit) != 0: return -1
    outgoing[tail] = outgoing[tail] or bit

  let full = (1 shl n)-1
  var dp: array[MaxStates, int64]
  for mask in 0 ..< MaxStates: dp[mask] = Inf
  dp[0] = 0
  for prefix in 0 .. full:
    if dp[prefix] == Inf: continue
    for vertex in 0 ..< n:
      let bit = 1 shl vertex
      if (prefix and bit) != 0: continue
      var backward = 0'i64
      for prior in 0 ..< n:
        if (prefix and (1 shl prior)) != 0 and (outgoing[vertex] and (1 shl prior)) != 0:
          inc backward
      let target = prefix or bit
      let candidate = dp[prefix] + backward
      if candidate < dp[target]: dp[target] = candidate
  dp[full]
