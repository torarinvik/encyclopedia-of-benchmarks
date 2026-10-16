const MaxVariables = 5
const MaxClauses = 10
const MaxClauseLength = 5
const MaxInputLength = 2 + MaxClauses * (1 + MaxClauseLength)
type ClauseMasks = array[MaxClauses, uint8]

proc dpll(positive, negative: ClauseMasks, variableCount, clauseCount: int,
          assignedInput, truthInput: uint8): bool =
  let universe = uint8((1 shl variableCount) - 1)
  var assigned = assignedInput
  var truth = truthInput
  while true:
    var changed = false
    var allSatisfied = true
    for clause in 0 ..< clauseCount:
      let pos = positive[clause]
      let neg = negative[clause]
      if (pos and neg) != 0 or (pos and truth) != 0 or
          (neg and (assigned and not truth)) != 0: continue
      allSatisfied = false
      let open = (pos or neg) and universe and not assigned
      if open == 0: return false
      if (open and (open - 1'u8)) == 0:
        if (pos and open) != 0: truth = truth or open
        else: truth = truth and not open
        assigned = assigned or open
        changed = true
        break
    if allSatisfied: return true
    if changed: continue
    var positiveOccurrences = 0'u8
    var negativeOccurrences = 0'u8
    for clause in 0 ..< clauseCount:
      let pos = positive[clause]
      let neg = negative[clause]
      if (pos and neg) != 0 or (pos and truth) != 0 or
          (neg and (assigned and not truth)) != 0: continue
      let open = (pos or neg) and universe and not assigned
      positiveOccurrences = positiveOccurrences or (pos and open)
      negativeOccurrences = negativeOccurrences or (neg and open)
    let pureTrue = positiveOccurrences and not negativeOccurrences
    let pureFalse = negativeOccurrences and not positiveOccurrences
    let pure = pureTrue or pureFalse
    if pure != 0:
      truth = (truth or pureTrue) and not pureFalse
      assigned = assigned or pure
      continue
    break
  for variable in 0 ..< variableCount:
    let bit = uint8(1 shl variable)
    if (assigned and bit) == 0:
      return dpll(positive, negative, variableCount, clauseCount, assigned or bit, truth or bit) or
        dpll(positive, negative, variableCount, clauseCount, assigned or bit, truth and not bit)
  false

proc davisPutnamLogemannLoveland*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "davis_putnam_logemann_loveland".} =
  if values == nil or length < 2 or length > csize_t(MaxInputLength): return -1
  let variableArg = values[0]
  let clauseArg = values[1]
  if variableArg < 0 or variableArg > MaxVariables or clauseArg < 0 or clauseArg > MaxClauses: return -1
  let variableCount = int(variableArg)
  let clauseCount = int(clauseArg)
  var positive: ClauseMasks
  var negative: ClauseMasks
  var position = 2
  for clause in 0 ..< clauseCount:
    if position >= int(length): return -1
    let literalCount = values[position]
    position += 1
    if literalCount < 0 or literalCount > MaxClauseLength or literalCount > int64(int(length) - position): return -1
    for _ in 0 ..< int(literalCount):
      let literal = values[position]
      position += 1
      if literal == 0 or literal < -variableArg or literal > variableArg: return -1
      let bit = uint8(1 shl (int(abs(literal)) - 1))
      if literal > 0: positive[clause] = positive[clause] or bit
      else: negative[clause] = negative[clause] or bit
  if position != int(length): return -1
  if dpll(positive, negative, variableCount, clauseCount, 0, 0): 1 else: 0
