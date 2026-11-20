const MaxVars = 12
const MaxClauses = 32
const MaxInput = 98
const MaxOutput = 104

proc putI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc reduceByLiteral(clauses: var array[MaxClauses, array[3, int]],
    lens: var array[MaxClauses, int], active: var array[MaxClauses, bool],
    count: int, literal: int): bool =
  for clause in 0 ..< count:
    if not active[clause]: continue
    var satisfied = false
    for at in 0 ..< lens[clause]:
      if clauses[clause][at] == literal: satisfied = true
    if satisfied:
      active[clause] = false
      continue
    var write = 0
    for at in 0 ..< lens[clause]:
      if clauses[clause][at] != -literal:
        clauses[clause][write] = clauses[clause][at]
        inc write
    lens[clause] = write
    if write == 0: return false
  true

proc chooseFreeLiteral(n: int, clauses: array[MaxClauses, array[3, int]],
    lens: array[MaxClauses, int], active: array[MaxClauses, bool],
    assigned: array[MaxVars, int]): int =
  var positive: array[MaxVars, int]
  var negative: array[MaxVars, int]
  for clause in 0 ..< MaxClauses:
    if active[clause]:
      for at in 0 ..< lens[clause]:
        let literal = clauses[clause][at]
        let variable = abs(literal) - 1
        if literal > 0: inc positive[variable]
        else: inc negative[variable]
  for variable in 0 ..< n:
    if assigned[variable] == 0 and (positive[variable] == 0 or negative[variable] == 0):
      if positive[variable] < negative[variable]: return variable + 1
      return -(variable + 1)
  var selected = -1
  var bestDifference = -1
  var bestTotal = -1
  for variable in 0 ..< n:
    if assigned[variable] != 0: continue
    let difference = abs(positive[variable] - negative[variable])
    let total = positive[variable] + negative[variable]
    if difference > bestDifference or (difference == bestDifference and total > bestTotal):
      selected = variable
      bestDifference = difference
      bestTotal = total
  if selected < 0: return 0
  if positive[selected] < negative[selected]: selected + 1
  else: -(selected + 1)

proc random_3sat_hajiaghayi_sorkin_algorithm_a*(values: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "random_3sat_hajiaghayi_sorkin_algorithm_a".} =
  if values == nil or length < 2 or length > csize_t(MaxInput): return -1
  if values[0] < 3 or values[0] > MaxVars or values[1] < 0 or values[1] > MaxClauses: return -1
  let n = int(values[0])
  let m = int(values[1])
  if int(length) != 2 + 3 * m: return -1

  var clauses: array[MaxClauses, array[3, int]]
  var lens: array[MaxClauses, int]
  var active: array[MaxClauses, bool]
  for clause in 0 ..< m:
    var seen: array[MaxVars, bool]
    for at in 0 ..< 3:
      let raw = values[2 + 3 * clause + at]
      if raw == 0 or raw < -n or raw > n: return -1
      let variable = int(if raw > 0: raw else: -raw) - 1
      if seen[variable]: return -1
      seen[variable] = true
      clauses[clause][at] = int(raw)
    lens[clause] = 3
    active[clause] = true

  var assigned: array[MaxVars, int]
  var assignedCount = 0
  var failed = false
  while assignedCount < n and not failed:
    let chosen = chooseFreeLiteral(n, clauses, lens, active, assigned)
    if chosen == 0:
      failed = true
      break
    let variable = abs(chosen) - 1
    assigned[variable] = if chosen > 0: 1 else: -1
    inc assignedCount
    if not reduceByLiteral(clauses, lens, active, m, chosen):
      failed = true
      break
    while not failed:
      var unit = 0
      for clause in 0 ..< m:
        if active[clause] and lens[clause] == 1:
          unit = clauses[clause][0]
          break
      if unit == 0: break
      let unitVariable = abs(unit) - 1
      assigned[unitVariable] = if unit > 0: 1 else: -1
      inc assignedCount
      if not reduceByLiteral(clauses, lens, active, m, unit): failed = true

  let byteCount = 8 * (n + 1)
  if output == nil or int(capacity) < byteCount: return -2
  var staged: array[MaxOutput, uint8]
  putI64(addr staged[0], 0, if failed: 0 else: 1)
  for variable in 0 ..< n:
    putI64(addr staged[0], 8 * (variable + 1), int64(assigned[variable]))
  for byte in 0 ..< byteCount: output[byte] = staged[byte]
  int64(byteCount)
