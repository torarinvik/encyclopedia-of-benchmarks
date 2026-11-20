type
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]
  Fraction = object
    numerator: int64
    denominator: int64
  PolicyContext = object
    rewards: array[12, int64]
    successors: array[12, int64]
    policy: array[4, int]
    values: array[4, Fraction]

const MaxStates = 4
const MaxActions = 3
const MaxOutputWords = 13

proc gcdU64(aValue, bValue: uint64): uint64 =
  var a = aValue
  var b = bValue
  while b != 0:
    let remainder = a mod b
    a = b
    b = remainder
  a

proc reduceFraction(numerator, denominator: int64): Fraction =
  let magnitude = if numerator < 0: uint64(-numerator) else: uint64(numerator)
  let divisor = gcdU64(magnitude, uint64(denominator))
  Fraction(numerator: numerator div int64(divisor), denominator: denominator div int64(divisor))

proc powerI64(base: int64, exponentValue: int): int64 =
  var result = 1'i64
  for _ in 0 ..< exponentValue: result *= base
  result

proc extendValue(reward: int64, successor: Fraction, p, q: int64): Fraction =
  reduceFraction(reward * successor.denominator * q + p * successor.numerator,
                 successor.denominator * q)

proc evaluatePolicy(context: var PolicyContext, states, actions: int, p, q: int64) =
  for start in 0 ..< states:
    var firstSeen: array[MaxStates, int]
    for i in 0 ..< MaxStates: firstSeen[i] = -1
    var path: array[MaxStates, int]
    var pathLength = 0
    var current = start
    while firstSeen[current] < 0:
      firstSeen[current] = pathLength
      path[pathLength] = current
      inc pathLength
      let state = path[pathLength - 1]
      let record = state * actions + context.policy[state]
      current = int(context.successors[record])
    let cycleStart = firstSeen[current]
    let cycleLength = pathLength - cycleStart
    var cycleNumerator = 0'i64
    for j in 0 ..< cycleLength:
      let state = path[cycleStart + j]
      let record = state * actions + context.policy[state]
      cycleNumerator += context.rewards[record] * powerI64(p, j) * powerI64(q, cycleLength - j)
    context.values[path[cycleStart]] = reduceFraction(cycleNumerator,
      powerI64(q, cycleLength) - powerI64(p, cycleLength))

    var j = pathLength
    while j > cycleStart + 1:
      let index = j - 1
      let state = path[index]
      let nextState = if index + 1 < pathLength: path[index + 1] else: path[cycleStart]
      let record = state * actions + context.policy[state]
      context.values[state] = extendValue(context.rewards[record], context.values[nextState], p, q)
      dec j
    j = cycleStart
    while j > 0:
      let index = j - 1
      let state = path[index]
      let record = state * actions + context.policy[state]
      context.values[state] = extendValue(context.rewards[record], context.values[path[index + 1]], p, q)
      dec j

proc improvePolicy(context: var PolicyContext, states, actions: int, p, q: int64): int =
  for state in 0 ..< states:
    var bestAction = 0
    let bestRecord = state * actions
    let bestNext = int(context.successors[bestRecord])
    var best = extendValue(context.rewards[bestRecord], context.values[bestNext], p, q)
    for action in 1 ..< actions:
      let record = state * actions + action
      let nextState = int(context.successors[record])
      let candidate = extendValue(context.rewards[record], context.values[nextState], p, q)
      if candidate.numerator * best.denominator > best.numerator * candidate.denominator:
        bestAction = action
        best = candidate
    if context.policy[state] != bestAction:
      context.policy[state] = bestAction
      inc result

proc writeI64Le(output: U8Output, offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255'u64)

proc mdp_policy_iteration*(input: I64Input, length: csize_t, output: U8Output,
    outputCapacity: csize_t): int64 {.cdecl, exportc: "mdp_policy_iteration".} =
  if input == nil or length < 4 or length > 28: return -1
  if input[0] < 1 or input[0] > MaxStates or input[1] < 1 or input[1] > MaxActions: return -1
  if input[3] < 1 or input[3] > 4 or input[2] < 0 or input[2] >= input[3]: return -1
  let states = int(input[0])
  let actions = int(input[1])
  let p = input[2]
  let q = input[3]
  if length != csize_t(4 + 2 * states * actions): return -1

  var context: PolicyContext
  for i in 0 ..< states * actions:
    let reward = input[4 + 2 * i]
    let successor = input[5 + 2 * i]
    if reward < -20 or reward > 20 or successor < 0 or successor >= int64(states): return -1
    context.rewards[i] = reward
    context.successors[i] = successor
  for state in 0 ..< MaxStates: context.values[state] = Fraction(numerator: 0, denominator: 1)
  var policyCount = 1
  for _ in 0 ..< states: policyCount *= actions
  var stable = false
  for _ in 0 ..< (policyCount + 1):
    evaluatePolicy(context, states, actions, p, q)
    if improvePolicy(context, states, actions, p, q) == 0:
      stable = true
      break
  if not stable: return -1

  var words: array[MaxOutputWords, int64]
  words[0] = int64(states)
  for state in 0 ..< states:
    words[1 + state] = int64(context.policy[state])
    words[1 + states + 2 * state] = context.values[state].numerator
    words[2 + states + 2 * state] = context.values[state].denominator
  let outputBytes = (1 + 3 * states) * 8
  if output == nil or outputCapacity < csize_t(outputBytes): return -2
  for i in 0 ..< 1 + 3 * states: writeI64Le(output, i * 8, words[i])
  int64(outputBytes)
