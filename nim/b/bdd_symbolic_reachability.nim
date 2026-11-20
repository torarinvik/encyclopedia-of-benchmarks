## ROBDD relational-product reachability for a tiny Boolean transition system.
const
  MaxInput = 133
  MaxNodes = 17000
  UniqueCap = 32768
  UniqueMask = UniqueCap - 1

type
  BddManager = object
    variable: array[MaxNodes, uint8]
    low: array[MaxNodes, uint16]
    high: array[MaxNodes, uint16]
    unique: array[UniqueCap, uint16]
    nextId: int
    variableCount: uint8
    failed: bool

proc uniqueHash(variable: uint8, low, high: uint16): int =
  (int(variable) * 4099 + int(low) * 131 + int(high)) and UniqueMask

proc makeNode(manager: var BddManager, variable: uint8,
              low, high: uint16): uint16 =
  if low == high: return low
  var slot = uniqueHash(variable, low, high)
  for _ in 0 ..< UniqueCap:
    let encoded = manager.unique[slot]
    if encoded == 0:
      if manager.nextId >= MaxNodes:
        manager.failed = true
        return 0
      let id = manager.nextId
      manager.variable[id] = variable
      manager.low[id] = low
      manager.high[id] = high
      manager.unique[slot] = uint16(id + 1)
      manager.nextId += 1
      return uint16(id)
    let id = int(encoded) - 1
    if manager.variable[id] == variable and manager.low[id] == low and manager.high[id] == high:
      return uint16(id)
    slot = (slot + 1) and UniqueMask
  manager.failed = true
  0

proc resetRound(manager: var BddManager, persistentNext: int) =
  for slot in 0 ..< UniqueCap: manager.unique[slot] = 0
  manager.nextId = persistentNext
  for id in 2 ..< persistentNext:
    var slot = uniqueHash(manager.variable[id], manager.low[id], manager.high[id])
    while manager.unique[slot] != 0:
      slot = (slot + 1) and UniqueMask
    manager.unique[slot] = uint16(id + 1)
  manager.failed = false

proc topVariable(manager: BddManager, node: uint16): uint8 =
  if node < 2: manager.variableCount else: manager.variable[node]

proc childrenAt(manager: BddManager, node: uint16, variable: uint8,
                low, high: var uint16) =
  if node >= 2 and manager.variable[node] == variable:
    low = manager.low[node]
    high = manager.high[node]
  else:
    low = node
    high = node

proc applyRecursive(manager: var BddManager, leftInput, rightInput: uint16,
                    isOr: bool): uint16 =
  if manager.failed: return 0
  var left = leftInput
  var right = rightInput
  if isOr:
    if left == 1 or right == 1: return 1
    if left == 0: return right
    if right == 0 or left == right: return left
  else:
    if left == 0 or right == 0: return 0
    if left == 1: return right
    if right == 1 or left == right: return left
  let variable = min(topVariable(manager, left), topVariable(manager, right))
  var leftLow, leftHigh, rightLow, rightHigh: uint16
  childrenAt(manager, left, variable, leftLow, leftHigh)
  childrenAt(manager, right, variable, rightLow, rightHigh)
  let low = applyRecursive(manager, leftLow, rightLow, isOr)
  let high = applyRecursive(manager, leftHigh, rightHigh, isOr)
  makeNode(manager, variable, low, high)

proc truthTableRecursive(manager: var BddManager, bits: ptr UncheckedArray[int64],
                         offset: int, variable: uint8, prefix: int,
                         variableCount: uint8): uint16 =
  if manager.failed: return 0
  if variable == variableCount: return uint16(bits[offset + prefix])
  let low = truthTableRecursive(manager, bits, offset, variable + 1, prefix * 2, variableCount)
  let high = truthTableRecursive(manager, bits, offset, variable + 1, prefix * 2 + 1, variableCount)
  makeNode(manager, variable, low, high)

proc stateSetRecursive(manager: var BddManager, mask: uint16,
                       variable: uint8, prefix: int,
                       variableCount: uint8): uint16 =
  if manager.failed: return 0
  if variable == variableCount: return uint16((mask shr prefix) and 1)
  let low = stateSetRecursive(manager, mask, variable + 1, prefix * 2, variableCount)
  let high = stateSetRecursive(manager, mask, variable + 1, prefix * 2 + 1, variableCount)
  makeNode(manager, variable, low, high)

proc existsRecursive(manager: var BddManager, node: uint16,
                     quantifiedVariables: uint8): uint16 =
  if manager.failed or node < 2: return node
  let variable = manager.variable[node]
  let low = existsRecursive(manager, manager.low[node], quantifiedVariables)
  let high = existsRecursive(manager, manager.high[node], quantifiedVariables)
  if variable < quantifiedVariables:
    applyRecursive(manager, low, high, true)
  else:
    makeNode(manager, variable, low, high)

proc renameRecursive(manager: var BddManager, node: uint16,
                     firstVariable: uint8): uint16 =
  if manager.failed or node < 2: return node
  let variable = manager.variable[node]
  if variable < firstVariable:
    manager.failed = true
    return 0
  let low = renameRecursive(manager, manager.low[node], firstVariable)
  let high = renameRecursive(manager, manager.high[node], firstVariable)
  makeNode(manager, variable - firstVariable, low, high)

proc evaluate(manager: BddManager, root: uint16,
              assignment: uint16, variableCount: uint8): uint16 =
  var node = root
  while node >= 2:
    let variable = manager.variable[node]
    let shift = int(variableCount - variable - 1)
    if ((assignment shr shift) and 1) != 0:
      node = manager.high[node]
    else:
      node = manager.low[node]
  node

proc bdd_symbolic_reachability*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "bdd_symbolic_reachability".} =
  if input == nil or length < 4 or length > csize_t(MaxInput): return -1
  let nRaw = input[0]
  let mRaw = input[1]
  let initialRaw = input[2]
  let invariantRaw = input[3]
  if nRaw < 1 or nRaw > 3 or mRaw < 0 or mRaw > 1: return -1
  let n = int(nRaw)
  let m = int(mRaw)
  let stateCount = 1 shl n
  let stateMask = (1 shl stateCount) - 1
  let relationLength = 1 shl (2 * n + m)
  if initialRaw < 0 or invariantRaw < 0 or
      (initialRaw shr stateCount) != 0 or (invariantRaw shr stateCount) != 0 or
      int(length) != 4 + relationLength: return -1
  for i in 0 ..< relationLength:
    if input[4 + i] != 0 and input[4 + i] != 1: return -1

  var manager: BddManager
  manager.nextId = 2
  manager.variableCount = uint8(2 * n + m)
  let relation = truthTableRecursive(manager, input, 4, 0, 0, manager.variableCount)
  if manager.failed: return -1
  let persistentNext = manager.nextId
  var reachedMask = uint16(initialRaw and int64(stateMask))

  for iteration in 0 .. stateCount:
    resetRound(manager, persistentNext)
    let reached = stateSetRecursive(manager, reachedMask, 0, 0, uint8(n))
    let product = applyRecursive(manager, reached, relation, false)
    let nextSet = existsRecursive(manager, product, uint8(n + m))
    let currentSet = renameRecursive(manager, nextSet, uint8(n + m))
    let joined = applyRecursive(manager, reached, currentSet, true)
    if manager.failed: return -1
    if joined == reached: break
    reachedMask = 0
    for state in 0 ..< stateCount:
      reachedMask = reachedMask or (evaluate(manager, joined, uint16(state), uint8(n)) shl state)
    if iteration == stateCount: return -1

  let violation = (reachedMask and not uint16(invariantRaw)) != 0
  (int64(reachedMask) shl 1) or int64(violation)
