const MAX_N = 6
const MAX_M = 4
const MAX_CALLS = MAX_N + 1
const MAX_INPUT = 122

type Formula = array[MAX_M, array[MAX_N, int64]]
type ClauseLengths = array[MAX_M, int]
type Values = array[MAX_N, int]

proc prefixSize(m: int): int =
  var remaining = m
  var bits = 0
  while remaining > 0:
    inc bits
    remaining = remaining shr 1
  bits + 1

proc litTrue(literal: int64, value: int): bool =
  if literal > 0: value == 1 else: value == 0

proc ppz(n, m: int, formula: Formula, lengths: ClauseLengths,
    fixed: Values, permutation, bits: array[MAX_N, int64],
    unitForces, randomGuesses: var int64): tuple[success: bool, local: Values] =
  var active: array[MAX_N, int]
  var activeCount = 0
  var local: Values
  for variable in 0..<MAX_N: local[variable] = -1
  for position in 0..<n:
    let variable = int(permutation[position]) - 1
    if fixed[variable] < 0:
      active[activeCount] = variable
      inc activeCount
  var work = formula
  var workLengths = lengths
  var workM = m
  for offset in 0..<activeCount:
    let variable = active[offset]
    var positiveUnit = false
    var negativeUnit = false
    for clause in 0..<workM:
      if workLengths[clause] == 1:
        positiveUnit = positiveUnit or work[clause][0] == int64(variable + 1)
        negativeUnit = negativeUnit or work[clause][0] == -int64(variable + 1)
    var value: int
    if positiveUnit:
      value = 1
      inc unitForces
    elif negativeUnit:
      value = 0
      inc unitForces
    else:
      value = int(bits[offset])
      inc randomGuesses
    local[variable] = value
    var next: Formula
    var nextLengths: ClauseLengths
    var nextM = 0
    for clause in 0..<workM:
      var satisfied = false
      var outLength = 0
      for item in 0..<workLengths[clause]:
        let literal = work[clause][item]
        if int(abs(literal)) - 1 != variable:
          next[nextM][outLength] = literal
          inc outLength
        elif litTrue(literal, value):
          satisfied = true
          break
      if not satisfied:
        nextLengths[nextM] = outLength
        inc nextM
    work = next
    workLengths = nextLengths
    workM = nextM
  for clause in 0..<workM:
    if workLengths[clause] == 0: return (false, local)
  (true, local)

proc restrictFormula(formula: Formula, lengths: ClauseLengths, m: int,
    assignment: Values): tuple[formula: Formula, lengths: ClauseLengths, count: int] =
  var next: Formula
  var nextLengths: ClauseLengths
  var nextM = 0
  for clause in 0..<m:
    var satisfied = false
    var outLength = 0
    for item in 0..<lengths[clause]:
      let literal = formula[clause][item]
      let value = assignment[int(abs(literal)) - 1]
      if value < 0:
        next[nextM][outLength] = literal
        inc outLength
      elif litTrue(literal, value):
        satisfied = true
        break
    if not satisfied:
      nextLengths[nextM] = outLength
      inc nextM
  (next, nextLengths, nextM)

proc putI64(output: ptr UncheckedArray[uint8], word: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8: output[word * 8 + byte] = uint8((bits shr (byte * 8)) and 255)

proc schuler_randomized_general_cnf_sat*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc:"schuler_randomized_general_cnf_sat".} =
  if input == nil or length < 2 or length > MAX_INPUT: return -1
  let n0 = input[0]
  let m0 = input[1]
  if n0 < 1 or n0 > MAX_N or m0 < 1 or m0 > MAX_M: return -1
  let n = int(n0)
  let originalM = int(m0)
  var formula: Formula
  var lengths: ClauseLengths
  var position = 2
  for clause in 0..<originalM:
    if position >= int(length): return -1
    let count0 = input[position]
    inc position
    if count0 < 1 or count0 > n0 or position + int(count0) > int(length): return -1
    var seen: array[MAX_N, bool]
    lengths[clause] = int(count0)
    for item in 0..<int(count0):
      let literal = input[position]
      inc position
      if literal == 0 or literal < -n0 or literal > n0: return -1
      let variable = int(abs(literal)) - 1
      if seen[variable]: return -1
      seen[variable] = true
      formula[clause][item] = literal

  var permutations: array[MAX_CALLS, array[MAX_N, int64]]
  var randomBits: array[MAX_CALLS, array[MAX_N, int64]]
  var choices: array[MAX_CALLS, int]
  for call in 0..n:
    var seen: array[MAX_N, bool]
    for item in 0..<n:
      if position >= int(length): return -1
      let value = input[position]
      inc position
      if value < 1 or value > n0 or seen[int(value) - 1]: return -1
      seen[int(value) - 1] = true
      permutations[call][item] = value
    for item in 0..<n:
      if position >= int(length) or (input[position] != 0 and input[position] != 1): return -1
      randomBits[call][item] = input[position]
      inc position
    if position >= int(length): return -1
    let choice = input[position]
    inc position
    if choice < 0 or choice >= m0: return -1
    choices[call] = int(choice)
  if position != int(length): return -1

  var fixed: Values
  for variable in 0..<MAX_N: fixed[variable] = -1
  var current = formula
  var currentLengths = lengths
  var currentM = originalM
  var calls = 0'i64
  var unitForces = 0'i64
  var randomGuesses = 0'i64
  var maxDepth = 0'i64
  var depth = 0
  var found = false
  var mask = 0'i64
  while true:
    inc calls
    maxDepth = max(maxDepth, int64(depth))
    if currentM == 0:
      found = true
      for variable in 0..<n:
        if fixed[variable] == 1: mask = mask or (1'i64 shl variable)
      break
    let k = prefixSize(currentM)
    var shortened: Formula
    var shortLengths: ClauseLengths
    for clause in 0..<currentM:
      shortLengths[clause] = min(currentLengths[clause], k)
      for item in 0..<shortLengths[clause]: shortened[clause][item] = current[clause][item]
    let ppzResult = ppz(n, currentM, shortened, shortLengths, fixed,
                        permutations[depth], randomBits[depth], unitForces, randomGuesses)
    if ppzResult.success:
      found = true
      for variable in 0..<n:
        if fixed[variable] == 1 or (fixed[variable] < 0 and ppzResult.local[variable] == 1):
          mask = mask or (1'i64 shl variable)
      break
    var eligible: array[MAX_M, int]
    var eligibleCount = 0
    for clause in 0..<currentM:
      if shortLengths[clause] == k:
        eligible[eligibleCount] = clause
        inc eligibleCount
    if eligibleCount == 0: break
    if choices[depth] >= eligibleCount: return -1
    let selected = eligible[choices[depth]]
    var nextFixed = fixed
    for item in 0..<k:
      let literal = shortened[selected][item]
      nextFixed[int(abs(literal)) - 1] = if literal > 0: 0 else: 1
    let restricted = restrictFormula(current, currentLengths, currentM, nextFixed)
    current = restricted.formula
    currentLengths = restricted.lengths
    currentM = restricted.count
    fixed = nextFixed
    inc depth
    if depth > n: return -1
  if not found: mask = 0
  let staged = [int64(ord(found)), mask, calls, unitForces, randomGuesses, maxDepth]
  if output == nil or capacity < 48: return -2
  for word in 0..<6: putI64(output, word, staged[word])
  48
