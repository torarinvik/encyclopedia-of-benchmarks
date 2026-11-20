const MaxN = 5
const MaxF = 5
const MaxQ = 8
const MaxP = 10
const MaxParseable = 128

proc put(outp: ptr UncheckedArray[uint8], at: int, value: int64) =
  let bits = cast[uint64](value)
  for i in 0 ..< 8: outp[at+i] = uint8((bits shr (8*i)) and 255)

proc stateCost(n, f: int, d: array[MaxP, array[MaxP, int64]], demand, assignment: array[MaxN, int64],
               fee: array[MaxF, int64], mask: uint32): int64 =
  var total = 0'i64
  for s in 0 ..< f:
    if (mask and (1'u32 shl s)) != 0: total += fee[s]
  for j in 0 ..< n: total += demand[j] * d[j][n + int(assignment[j])]
  total

proc facility_location_randomized_add_delete_many*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "facility_location_randomized_add_delete_many".} =
  if input.isNil or length < 12 or length > csize_t(MaxParseable): return -1
  let n0 = input[0]; let f0 = input[1]; let q0 = input[2]; let raw = input[3]
  if n0 < 1 or n0 > 5 or f0 < 1 or f0 > 5 or q0 < 1 or q0 > 8 or raw <= 0 or uint64(raw) >= (1'u64 shl int(f0)): return -1
  let n = int(n0); let f = int(f0); let q = int(q0); let p = n + f
  if int(length) != 4 + 2*n + p*p + f + q: return -1
  var mask = uint32(raw)
  var assignment, demand: array[MaxN, int64]
  var d: array[MaxP, array[MaxP, int64]]
  var fee: array[MaxF, int64]
  var tape: array[MaxQ, int64]
  var pos = 4
  for j in 0 ..< n:
    assignment[j] = input[pos]; inc pos
    if assignment[j] < 0 or assignment[j] >= f0 or (mask and (1'u32 shl int(assignment[j]))) == 0: return -1
  for j in 0 ..< n:
    demand[j] = input[pos]; inc pos
    if demand[j] < 1 or demand[j] > 10: return -1
  for i in 0 ..< p:
    for j in 0 ..< p:
      let value = input[pos]; inc pos
      if value < 0 or value > 1000: return -1
      d[i][j] = value
  for i in 0 ..< p:
    if d[i][i] != 0: return -1
    for j in 0 ..< p:
      if i != j and d[i][j] == 0: return -1
      if d[i][j] != d[j][i]: return -1
      for k in 0 ..< p:
        if d[i][j] > d[i][k] + d[k][j]: return -1
  for s in 0 ..< f:
    fee[s] = input[pos]; inc pos
    if fee[s] < 0 or fee[s] > 1000: return -1
  for t in 0 ..< q:
    tape[t] = input[pos]; inc pos
    if tape[t] < 0 or tape[t] >= f0: return -1
  var costs, accepted: array[MaxQ, int64]
  var current = stateCost(n, f, d, demand, assignment, fee, mask)
  var count = 0'i64
  for step in 0 ..< q:
    let candidate = int(tape[step]); let bit = 1'u32 shl candidate
    var did = 0'i64
    if (mask and bit) == 0:
      var closer: array[MaxN, bool]
      var gain = -fee[candidate]
      for j in 0 ..< n:
        let old = int(assignment[j])
        if d[j][n+candidate] < d[j][n+old]:
          closer[j] = true
          gain += demand[j] * (d[j][n+old] - d[j][n+candidate])
      var drop = 0'u32
      for s in 0 ..< f:
        if (mask and (1'u32 shl s)) != 0:
          var centerGain = fee[s]
          for j in 0 ..< n:
            if int(assignment[j]) == s and not closer[j]:
              centerGain += demand[j] * (d[j][n+s] - d[j][n+candidate])
          if centerGain > 0:
            drop = drop or (1'u32 shl s)
            gain += centerGain
      if gain > 0:
        mask = (mask or bit) and not drop
        for j in 0 ..< n:
          if closer[j] or (drop and (1'u32 shl int(assignment[j]))) != 0: assignment[j] = int64(candidate)
        current = stateCost(n, f, d, demand, assignment, fee, mask)
        did = 1
        inc count
    costs[step] = current
    accepted[step] = did
  let outBytes = 8 * (2*q + 3 + n)
  if output.isNil or capacity < csize_t(outBytes): return -2
  pos = 0
  for t in 0 ..< q: put(output, pos, costs[t]); pos += 8
  for t in 0 ..< q: put(output, pos, accepted[t]); pos += 8
  put(output, pos, current); pos += 8
  put(output, pos, int64(mask)); pos += 8
  for j in 0 ..< n: put(output, pos, assignment[j]); pos += 8
  put(output, pos, count); pos += 8
  int64(pos)
