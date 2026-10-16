const MaxLeaves = 32
const MaxOperations = 64
const MaxNodes = 96
const InvalidResult = -1.0e300

proc integerPower(value: float64, exponent: int): float64 =
  var result = 1.0
  for _ in 0 ..< exponent: result *= value
  result

proc automatic_differentiation*(input: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "automatic_differentiation".} =
  if input.isNil or length < 8: return InvalidResult
  let leavesValue = input[0]
  let operationsValue = input[1]
  if leavesValue < 1 or leavesValue > MaxLeaves.int64 or
      operationsValue < 1 or operationsValue > MaxOperations.int64: return InvalidResult
  let leaves = int(leavesValue)
  let operationCount = int(operationsValue)
  if length != csize_t(4 + leaves + 3 * operationCount): return InvalidResult
  let nodeCount = leaves + operationCount
  let targetValue = input[2]
  let sourceValue = input[3]
  if targetValue < leavesValue or targetValue >= int64(nodeCount) or
      sourceValue < 0 or sourceValue >= leavesValue: return InvalidResult
  let target = int(targetValue)
  let source = int(sourceValue)

  var nodes: array[MaxNodes, float64]
  var opcodes: array[MaxOperations, int64]
  var leftNodes: array[MaxOperations, int]
  var rightFields: array[MaxOperations, int64]
  for index in 0 ..< leaves:
    let value = input[4 + index]
    if value < -16 or value > 16: return InvalidResult
    nodes[index] = float64(value)

  var offset = 4 + leaves
  for operation in 0 ..< operationCount:
    let opcode = input[offset]
    let leftValue = input[offset + 1]
    let rightValue = input[offset + 2]
    let outputNode = leaves + operation
    if leftValue < 0 or leftValue >= int64(outputNode): return InvalidResult
    let left = int(leftValue)
    var result: float64
    if opcode == 5:
      if rightValue < 1 or rightValue > 8: return InvalidResult
      result = integerPower(nodes[left], int(rightValue))
    else:
      if opcode < 0 or opcode > 3 or rightValue < 0 or rightValue >= int64(outputNode):
        return InvalidResult
      let right = int(rightValue)
      if opcode == 0: result = nodes[left] + nodes[right]
      elif opcode == 1: result = nodes[left] - nodes[right]
      elif opcode == 2: result = nodes[left] * nodes[right]
      else:
        if nodes[right] == 0.0: return InvalidResult
        result = nodes[left] / nodes[right]
    if result != result or result < -10_000_000_000.0 or result > 10_000_000_000.0:
      return InvalidResult
    nodes[outputNode] = result
    opcodes[operation] = opcode
    leftNodes[operation] = left
    rightFields[operation] = rightValue
    offset += 3

  var adjoints: array[MaxNodes, float64]
  var ancestors: array[MaxNodes, bool]
  adjoints[target] = 1.0
  ancestors[target] = true
  for cursor in countdown(target - leaves, 0):
    let outputNode = leaves + cursor
    if not ancestors[outputNode]: continue
    let left = leftNodes[cursor]
    let adjoint = adjoints[outputNode]
    ancestors[left] = true
    case opcodes[cursor]
    of 0:
      let right = int(rightFields[cursor])
      ancestors[right] = true
      adjoints[left] += adjoint
      adjoints[right] += adjoint
    of 1:
      let right = int(rightFields[cursor])
      ancestors[right] = true
      adjoints[left] += adjoint
      adjoints[right] -= adjoint
    of 2:
      let right = int(rightFields[cursor])
      ancestors[right] = true
      adjoints[left] += nodes[right] * adjoint
      adjoints[right] += nodes[left] * adjoint
    of 3:
      let right = int(rightFields[cursor])
      let leftValue = nodes[left]
      let rightValue = nodes[right]
      ancestors[right] = true
      adjoints[left] += (1.0 / rightValue) * adjoint
      adjoints[right] += (-leftValue / (rightValue * rightValue)) * adjoint
    of 5:
      let exponent = int(rightFields[cursor])
      let localDerivative = float64(exponent) * integerPower(nodes[left], exponent - 1)
      adjoints[left] += localDerivative * adjoint
    else: return InvalidResult
  if not ancestors[source] or adjoints[source] != adjoints[source] or
      adjoints[source] < -1.0e300 or adjoints[source] > 1.0e300: return InvalidResult
  adjoints[source]
