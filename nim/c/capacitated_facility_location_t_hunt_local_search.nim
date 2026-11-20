const MaxN = 4
const MaxF = 3
const MaxInitialCopies = 4
const MaxCopies = 644
const MaxCandidateCopies = 648
const MaxP = 7
const MaxValidInput = 62
const MaxParseableInput = 63
const MaxOutputBytes = 5208
const NegInf = low(int64) div 4

proc putWord(output: ptr UncheckedArray[uint8], at: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8:
    output[at + b] = uint8((bits shr (8 * b)) and 255'u64)

proc insertType(types: var array[MaxCandidateCopies, int64], copies: var int,
                kind: int64) =
  var at = copies
  while at > 0 and types[at - 1] > kind:
    types[at] = types[at - 1]
    dec at
  types[at] = kind
  inc copies

proc assignState(n, f: int, d: array[MaxP, array[MaxP, int64]],
                 fees, caps: array[MaxF, int64], types: openArray[int64],
                 copies: int, assignment: var array[MaxN, int64]): int64 =
  var multiplicity: array[MaxF, int]
  for copy in 0 ..< copies:
    inc multiplicity[int(types[copy])]
  var combinations = 1
  for _ in 0 ..< n:
    combinations *= f
  var bestService = high(int64)
  var bestTypes: array[MaxN, int]
  for code in 0 ..< combinations:
    var remainder = code
    var candidate: array[MaxN, int]
    var loads: array[MaxF, int]
    var service = 0'i64
    for offset in 0 ..< n:
      let client = n - 1 - offset
      let kind = remainder mod f
      remainder = remainder div f
      candidate[client] = kind
      inc loads[kind]
      service += d[client][n + kind]
    var feasible = true
    for kind in 0 ..< f:
      if loads[kind] > multiplicity[kind] * int(caps[kind]):
        feasible = false
    if feasible and service < bestService:
      bestService = service
      for client in 0 ..< n:
        bestTypes[client] = candidate[client]

  var copyLoads: array[MaxCandidateCopies, int]
  for client in 0 ..< n:
    assignment[client] = -1
    for copy in 0 ..< copies:
      let kind = int(types[copy])
      if assignment[client] == -1 and kind == bestTypes[client] and
          copyLoads[copy] < int(caps[kind]):
        assignment[client] = int64(copy)
        inc copyLoads[copy]
  var total = bestService
  for copy in 0 ..< copies:
    total += fees[int(types[copy])]
  total

proc tHunt(n, f: int, d: array[MaxP, array[MaxP, int64]],
           fees, caps: array[MaxF, int64], types: openArray[int64], copies: int,
           assignment: array[MaxN, int64], target, copiesAdded: int,
           selected: var array[MaxCopies, bool]): int64 =
  var loads: array[MaxCopies, int]
  var profits: array[MaxCopies, int64]
  let points = n + f
  for copy in 0 ..< copies:
    profits[copy] = fees[int(types[copy])]
  for client in 0 ..< n:
    let copy = int(assignment[client])
    let oldType = int(types[copy])
    inc loads[copy]
    profits[copy] += d[client][n + oldType] - d[client][n + target]

  let limit = min(n, copiesAdded * int(caps[target]))
  var dp: array[MaxN + 1, int64]
  for weight in 0 .. MaxN:
    dp[weight] = NegInf
  dp[0] = 0
  var take: array[MaxCopies, array[MaxN + 1, bool]]
  for copy in 0 ..< copies:
    var next = dp
    for weight in 0 .. limit:
      take[copy][weight] = false
    for weight in 0 .. limit:
      let newWeight = weight + loads[copy]
      if dp[weight] != NegInf and newWeight <= limit:
        let value = dp[weight] + profits[copy]
        if value > next[newWeight]:
          next[newWeight] = value
          take[copy][newWeight] = true
    dp = next

  var bestProfit = NegInf
  var bestWeight = 0
  for weight in 0 .. limit:
    if dp[weight] > bestProfit:
      bestProfit = dp[weight]
      bestWeight = weight
  for copy in 0 ..< copies:
    selected[copy] = false
  var used = bestWeight
  for offset in 0 ..< copies:
    let copy = copies - 1 - offset
    if take[copy][used]:
      selected[copy] = true
      used -= loads[copy]
  bestProfit

proc capacitated_facility_location_t_hunt_local_search*(
    input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "capacitated_facility_location_t_hunt_local_search".} =
  if input == nil or length < 10 or length > MaxParseableInput: return -1
  let nr = input[0]
  let fr = input[1]
  let qr = input[2]
  if nr < 1 or nr > MaxN or fr < 1 or fr > MaxF or qr < 1 or qr > MaxInitialCopies: return -1
  let n = int(nr)
  let f = int(fr)
  let q = int(qr)
  let points = n + f
  if length != csize_t(3 + points * points + 2 * f + q): return -1

  var d: array[MaxP, array[MaxP, int64]]
  var fees: array[MaxF, int64]
  var caps: array[MaxF, int64]
  var types: array[MaxCandidateCopies, int64]
  var at = 3
  for i in 0 ..< points:
    for j in 0 ..< points:
      let value = input[at]
      inc at
      if value < 0 or value > 20: return -1
      d[i][j] = value
  for i in 0 ..< points:
    if d[i][i] != 0: return -1
    for j in 0 ..< points:
      if i != j and d[i][j] == 0: return -1
      if d[i][j] != d[j][i]: return -1
      for k in 0 ..< points:
        if d[i][j] > d[i][k] + d[k][j]: return -1
  for kind in 0 ..< f:
    fees[kind] = input[at]
    inc at
    if fees[kind] < 0 or fees[kind] > 20: return -1
  for kind in 0 ..< f:
    caps[kind] = input[at]
    inc at
    if caps[kind] < 1 or caps[kind] > nr: return -1
  var totalCapacity = 0
  for copy in 0 ..< q:
    let kind = input[at]
    inc at
    if kind < 0 or kind >= fr: return -1
    types[copy] = kind
    totalCapacity += int(caps[int(kind)])
  if totalCapacity < n: return -1
  var copies = q
  for i in 1 ..< copies:
    let value = types[i]
    var j = i
    while j > 0 and types[j - 1] > value:
      types[j] = types[j - 1]
      dec j
    types[j] = value

  var assignment: array[MaxN, int64]
  var current = assignState(n, f, d, fees, caps, types, copies, assignment)
  var steps = 0
  while steps < 160:
    var moved = false
    for target in 0 ..< f:
      var candidateTypes = types
      var candidateCopies = copies
      insertType(candidateTypes, candidateCopies, int64(target))
      var candidateAssignment: array[MaxN, int64]
      let addedCost = assignState(n, f, d, fees, caps, candidateTypes,
                                  candidateCopies, candidateAssignment)
      if addedCost < current:
        types = candidateTypes
        copies = candidateCopies
        current = addedCost
        assignment = candidateAssignment
        inc steps
        moved = true
        break
      var selected: array[MaxCopies, bool]
      for copiesAdded in 1 .. n:
        let profit = tHunt(n, f, d, fees, caps, types, copies, assignment,
                           target, copiesAdded, selected)
        if profit <= int64(copiesAdded) * fees[target]: continue
        var dropCount = 0
        for copy in 0 ..< copies:
          if not selected[copy]:
            candidateTypes[dropCount] = types[copy]
            inc dropCount
        candidateCopies = dropCount
        for _ in 0 ..< copiesAdded:
          insertType(candidateTypes, candidateCopies, int64(target))
        let nextCost = assignState(n, f, d, fees, caps, candidateTypes,
                                   candidateCopies, candidateAssignment)
        if nextCost < current:
          types = candidateTypes
          copies = candidateCopies
          current = nextCost
          assignment = candidateAssignment
          inc steps
          moved = true
          break
      if moved: break
    if not moved: break

  let words = 3 + copies + n
  let bytes = 8 * words
  if output == nil or capacity < csize_t(bytes): return -2
  putWord(output, 0, current)
  putWord(output, 8, int64(steps))
  putWord(output, 16, int64(copies))
  var outAt = 24
  for copy in 0 ..< copies:
    putWord(output, outAt, types[copy])
    outAt += 8
  for client in 0 ..< n:
    putWord(output, outAt, assignment[client])
    outAt += 8
  int64(bytes)
