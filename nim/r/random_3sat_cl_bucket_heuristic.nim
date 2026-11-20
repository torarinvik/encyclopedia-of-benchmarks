const MaxVars = 8
const MaxClauses = 24
const MaxParseableInput = 99
const MaxWords = 44

type
  Formula = object
    literals: array[MaxClauses, array[3, int]]
    lengths: array[MaxClauses, int]
    active: array[MaxClauses, bool]
  Event = object
    literal, kind, bi, bj: int64

proc putI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc simplify(f: var Formula, m: int, assigned: var array[MaxVars, int], literal: int): bool =
  let variable = abs(literal) - 1
  let value = (if literal > 0: 1 else: -1)
  if assigned[variable] != 0 and assigned[variable] != value: return false
  assigned[variable] = value
  for c in 0 ..< m:
    if not f.active[c]: continue
    var satisfied = false
    for j in 0 ..< f.lengths[c]:
      if f.literals[c][j] == literal: satisfied = true
    if satisfied:
      f.active[c] = false
      continue
    var kept = 0
    for j in 0 ..< f.lengths[c]:
      if f.literals[c][j] != -literal:
        f.literals[c][kept] = f.literals[c][j]
        inc kept
    f.lengths[c] = kept
    if kept == 0: return false
  true

proc propagate(f: var Formula, m: int, assigned: var array[MaxVars, int],
               events: var array[MaxVars, Event], count: var int, record: bool): bool =
  while true:
    var unit = 0
    for c in 0 ..< m:
      if f.active[c] and f.lengths[c] == 1:
        unit = f.literals[c][0]
        break
    if unit == 0: return true
    if record:
      events[count] = Event(literal: int64(unit), kind: 1, bi: -1, bj: -1)
      inc count
    if not simplify(f, m, assigned, unit): return false

proc allDegrees(f: Formula, m, n: int): tuple[pos, neg: array[MaxVars, int]] =
  var result: tuple[pos, neg: array[MaxVars, int]]
  for c in 0 ..< m:
    if f.active[c]:
      for j in 0 ..< f.lengths[c]:
        let x = f.literals[c][j]
        if x > 0: inc result.pos[x - 1]
        else: inc result.neg[-x - 1]
  discard n
  result

proc member(f: Formula, m, n: int, assigned: array[MaxVars, int], bi, bj: int): int =
  let (pos, neg) = allDegrees(f, m, n)
  for v in 0 ..< n:
    if assigned[v] != 0: continue
    let p = min(10, pos[v])
    let q = min(10, neg[v])
    if p == bi and q == bj: return v + 1
    if q == bi and p == bj: return -(v + 1)
  0

proc flowSums(f: Formula, m, n: int): tuple[s2, s3, den: int64] =
  var p2, n2, p3, n3: array[MaxVars, int64]
  var clauses2 = 0'i64
  for c in 0 ..< m:
    if not f.active[c]: continue
    if f.lengths[c] == 2:
      inc clauses2
      for j in 0 ..< 2:
        let x = f.literals[c][j]
        if x > 0: inc p2[x - 1] else: inc n2[-x - 1]
    elif f.lengths[c] == 3:
      for j in 0 ..< 3:
        let x = f.literals[c][j]
        if x > 0: inc p3[x - 1] else: inc n3[-x - 1]
  var s2 = 0'i64
  var s3 = 0'i64
  for c in 0 ..< m:
    if f.active[c] and f.lengths[c] == 2:
      for j in 0 ..< 2:
        let x = -f.literals[c][j]
        if x > 0:
          s2 += p2[x - 1]
          s3 += p3[x - 1]
        else:
          s2 += n2[-x - 1]
          s3 += n3[-x - 1]
  discard n
  (s2: s2, s3: s3, den: (if clauses2 == 0: 1'i64 else: 2 * clauses2))

proc chooseBucket(f: Formula, m, n: int, assigned: array[MaxVars, int]
                  ): tuple[found: bool, bi, bj: int] =
  let old = flowSums(f, m, n)
  var found = false
  var bestNum = 0'i64
  var bestDen = 1'i64
  var bestI = -1
  var bestJ = -1
  for bi in 0 .. 10:
    for bj in 0 .. 10:
      let literal = member(f, m, n, assigned, bi, bj)
      if literal == 0: continue
      var trial = f
      var trialAssigned = assigned
      var ignoredEvents: array[MaxVars, Event]
      var ignoredCount = 0
      if not simplify(trial, m, trialAssigned, literal): continue
      if not propagate(trial, m, trialAssigned, ignoredEvents, ignoredCount, false): continue
      let next = flowSums(trial, m, n)
      var numerator = next.s2 * old.den - old.s2 * next.den
      var denominator = next.s3 * old.den - old.s3 * next.den
      if denominator == 0: continue
      if denominator < 0:
        numerator = -numerator
        denominator = -denominator
      if not found or numerator * bestDen > bestNum * denominator or
         (numerator * bestDen == bestNum * denominator and (bi < bestI or (bi == bestI and bj < bestJ))):
        found = true
        bestNum = numerator
        bestDen = denominator
        bestI = bi
        bestJ = bj
  (found: found, bi: bestI, bj: bestJ)

proc random_3sat_cl_bucket_heuristic*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "random_3sat_cl_bucket_heuristic".} =
  if input == nil or length < 2 or length > csize_t(MaxParseableInput): return -1
  if input[0] < 1 or input[0] > MaxVars or input[1] < 0 or input[1] > MaxClauses: return -1
  let n = int(input[0])
  let m = int(input[1])
  if int(length) != 2 + 4 * m: return -1
  var f: Formula
  for c in 0 ..< m:
    let base = 2 + 4 * c
    let rawK = input[base]
    if rawK < 1 or rawK > 3: return -1
    let k = int(rawK)
    var seen: array[MaxVars, bool]
    f.lengths[c] = k
    for j in 0 ..< 3:
      let raw = input[base + 1 + j]
      if j < k:
        if raw == 0 or raw < -int64(n) or raw > int64(n): return -1
        let v = int(if raw > 0: raw else: -raw) - 1
        if seen[v]: return -1
        seen[v] = true
        f.literals[c][j] = int(raw)
      elif raw != 0: return -1
    f.active[c] = true

  var assigned: array[MaxVars, int]
  var events: array[MaxVars, Event]
  var eventCount = 0
  var status = 0'i64
  if not propagate(f, m, assigned, events, eventCount, true): status = 1
  while status == 0:
    var pending = false
    for v in 0 ..< n: pending = pending or assigned[v] == 0
    if not pending: break
    let choice = chooseBucket(f, m, n, assigned)
    if not choice.found: status = 2; break
    let literal = member(f, m, n, assigned, choice.bi, choice.bj)
    if literal == 0: status = 2; break
    events[eventCount] = Event(literal: int64(literal), kind: 0,
                                bi: int64(choice.bi), bj: int64(choice.bj))
    inc eventCount
    if not simplify(f, m, assigned, literal): status = 1; break
    if not propagate(f, m, assigned, events, eventCount, true): status = 1; break

  var words: array[MaxWords, int64]
  var at = 0
  words[at] = status; inc at
  words[at] = int64(n); inc at
  var assignedCount = 0
  for v in 0 ..< n: assignedCount += int(assigned[v] != 0)
  words[at] = int64(assignedCount); inc at
  for v in 0 ..< n: words[at] = int64(assigned[v]); inc at
  words[at] = int64(eventCount); inc at
  for i in 0 ..< eventCount:
    words[at] = events[i].literal; inc at
    words[at] = events[i].kind; inc at
    words[at] = events[i].bi; inc at
    words[at] = events[i].bj; inc at
  let bytes = 8 * at
  if output == nil or int(capacity) < bytes: return -2
  var staged: array[352, uint8]
  for i in 0 ..< at: putI64(addr staged[0], 8 * i, words[i])
  for i in 0 ..< bytes: output[i] = staged[i]
  int64(bytes)
