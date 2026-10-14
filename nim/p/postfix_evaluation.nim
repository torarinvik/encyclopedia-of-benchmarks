## Evaluate bounded integer postfix expressions with an explicit operand stack.
const InvalidResult = -1000000001'i64

proc applyOperator(opcode, left, right: int64): int64 =
  var value: int64
  case opcode
  of 1: value = left + right
  of 2: value = left - right
  of 3: value = left * right
  of 4:
    if right == 0: return InvalidResult
    let magnitudeLeft = if left < 0: -left else: left
    let magnitudeRight = if right < 0: -right else: right
    let quotient = magnitudeLeft div magnitudeRight
    value = if (left < 0) != (right < 0): -quotient else: quotient
  else: return InvalidResult
  if value < -1000000000 or value > 1000000000: InvalidResult else: value

proc postfix_evaluation*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "postfix_evaluation".} =
  if length < 2 or length > 512 or length mod 2 != 0: return InvalidResult
  let tokenCount = int(length div 2)
  var stack: array[256, int64]
  var top = 0
  for token in 0 ..< tokenCount:
    let opcode = values[2 * token]
    let operand = values[2 * token + 1]
    if opcode == 0:
      if operand < -1000000 or operand > 1000000: return InvalidResult
      stack[top] = operand
      inc top
    else:
      if opcode < 1 or opcode > 4 or operand != 0 or top < 2: return InvalidResult
      dec top
      let right = stack[top]
      dec top
      let left = stack[top]
      let result = applyOperator(opcode, left, right)
      if result == InvalidResult: return InvalidResult
      stack[top] = result
      inc top
  if top != 1: return InvalidResult
  stack[0]
