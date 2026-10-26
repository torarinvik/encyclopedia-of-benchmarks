const MaxN = 8
const MaxClauses = 12
const MaxInput = 54
const MaxOutput = 72

type Clause = array[3, int64]
     Clauses = array[MaxClauses, Clause]
     Assignment = array[MaxN, int]

proc put(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc fixedMask(mask0: int, assigned: Assignment, n: int): int =
  result = mask0
  for i in 0..<n:
    if assigned[i] >= 0:
      if assigned[i] == 1: result = result or (1 shl i)
      else: result = result and not (1 shl i)

proc clauseTrue(clause: Clause, mask: int): bool =
  for literal in clause:
    let bit = (mask shr (int(abs(literal)) - 1)) and 1
    if (literal > 0 and bit == 1) or (literal < 0 and bit == 0): return true
  false

proc selectedTrue(clauses: Clauses, m, subset, mask: int): bool =
  for i in 0..<m:
    if (subset and (1 shl i)) != 0 and not clauseTrue(clauses[i], mask): return false
  true

proc popcount(value0: int): int =
  var value = value0
  while value > 0:
    result += value and 1
    value = value shr 1

proc currentSat(n, m: int, clauses: Clauses, assigned: Assignment): bool =
  for mask in 0..<(1 shl n):
    if selectedTrue(clauses, m, (1 shl m) - 1, fixedMask(mask, assigned, n)): return true
  false

proc findForce(n, m: int, clauses: Clauses, assigned: Assignment): tuple[found: bool, variable: int, value: int] =
  if not currentSat(n, m, clauses, assigned): return (false, -1, -1)
  var threshold = 0
  while (1 shl (threshold + 1)) <= n: inc threshold
  var implied: Assignment
  for i in 0..<MaxN: implied[i] = -1
  for subset in 1..<(1 shl m):
    if popcount(subset) > threshold: continue
    var seenZero, seenOne: array[MaxN, bool]
    for mask in 0..<(1 shl n):
      let full = fixedMask(mask, assigned, n)
      if selectedTrue(clauses, m, subset, full):
        for x in 0..<n:
          if assigned[x] < 0:
            if ((full shr x) and 1) == 1: seenOne[x] = true
            else: seenZero[x] = true
    for x in 0..<n:
      if assigned[x] < 0 and seenZero[x] != seenOne[x] and implied[x] < 0:
        implied[x] = if seenOne[x]: 1 else: 0
  for x in 0..<n:
    if implied[x] >= 0: return (true, x, implied[x])
  (false, -1, -1)

proc ppsz_k_sat_trace*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "ppsz_k_sat_trace".} =
  if input.isNil or length < 2 or length > MaxInput: return -1
  if input[0] < 3 or input[0] > MaxN or input[1] < 0 or input[1] > MaxClauses: return -1
  let n = int(input[0]); let m = int(input[1])
  if int(length) != 2 + 3 * m + 2 * n: return -1
  var clauses: Clauses
  for i in 0..<m:
    var seen: array[MaxN, bool]
    for j in 0..<3:
      let literal = input[2 + 3 * i + j]
      if literal == 0 or literal < -int64(n) or literal > int64(n): return -1
      let variable = int(abs(literal)) - 1
      if seen[variable]: return -1
      seen[variable] = true; clauses[i][j] = literal
  let start = 2 + 3 * m
  var order, beta: array[MaxN, int]
  var seenVariable: array[MaxN, bool]
  var assigned: Assignment
  for i in 0..<MaxN: assigned[i] = -1
  for i in 0..<n:
    let variable = input[start + i]
    if variable < 0 or variable >= int64(n) or seenVariable[int(variable)]: return -1
    order[i] = int(variable); seenVariable[int(variable)] = true
  for i in 0..<n:
    let bit = input[start + n + i]
    if bit != 0 and bit != 1: return -1
    beta[i] = int(bit)
  for step in 0..<n:
    while true:
      let forced = findForce(n, m, clauses, assigned)
      if not forced.found: break
      assigned[forced.variable] = forced.value
    let variable = order[step]
    if assigned[variable] < 0: assigned[variable] = beta[variable]
  var mask = 0
  for i in 0..<n: if assigned[i] == 1: mask = mask or (1 shl i)
  let verdict = if selectedTrue(clauses, m, (1 shl m) - 1, mask): 1'i64 else: 0'i64
  let bytes = 8 * (n + 1)
  if output.isNil or capacity < csize_t(bytes): return -2
  var staged: array[MaxOutput, uint8]
  put(addr staged[0], 0, verdict)
  for i in 0..<n: put(addr staged[0], 8 * (i + 1), int64(assigned[i]))
  for i in 0..<bytes: output[i] = staged[i]
  int64(bytes)
