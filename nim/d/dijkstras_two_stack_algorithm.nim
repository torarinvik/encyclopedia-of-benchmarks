const InvalidResult = -1_000_000_001'i64

proc applyOperator(opcode, left, right: int64): int64 =
  var result: int64
  case opcode
  of 43: result = left + right
  of 45: result = left - right
  of 42: result = left * right
  of 47:
    if right == 0 or left mod right != 0: return InvalidResult
    result = left div right
  else: return InvalidResult
  if result < -1_000_000_000 or result > 1_000_000_000: InvalidResult else: result

proc dijkstras_two_stack_algorithm*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "dijkstras_two_stack_algorithm".} =
  if values == nil or length == 0 or length > 511: return InvalidResult
  var operands, operators: array[256, int64]
  var operandTop, operatorTop, parentheses = 0
  for index in 0 ..< int(length):
    let token = values[index]
    if token >= 48 and token <= 57:
      if operandTop == 256: return InvalidResult
      operands[operandTop] = token - 48
      inc operandTop
    elif token == 40:
      inc parentheses
      if parentheses > 128: return InvalidResult
    elif token == 43 or token == 45 or token == 42 or token == 47:
      if operatorTop == 256: return InvalidResult
      operators[operatorTop] = token
      inc operatorTop
    elif token == 41:
      if parentheses == 0 or operatorTop == 0 or operandTop < 2: return InvalidResult
      dec parentheses
      dec operatorTop
      let opcode = operators[operatorTop]
      dec operandTop
      let right = operands[operandTop]
      dec operandTop
      let left = operands[operandTop]
      let computed = applyOperator(opcode, left, right)
      if computed == InvalidResult: return InvalidResult
      operands[operandTop] = computed
      inc operandTop
    else: return InvalidResult
  if parentheses != 0 or operatorTop != 0 or operandTop != 1: return InvalidResult
  operands[0]
