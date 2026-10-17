import std/math

const InvalidResult = -1.0e300
const MaxInputValues = 257
const MaxExpressionBytes = 255
const MaxOperands = 16
const MaxOperators = 15
const MaxLiteralBytes = 16
const MaxLiteralValue = 1_000_000.0
const MaxIntermediate = 1_000_000_000_000.0

proc roundedMultiply(left, right: float64): float64 {.noinline.} = left * right
proc roundedAdd(left, right: float64): float64 {.noinline.} = left + right
proc roundedDivide(left, right: float64): float64 {.noinline.} = left / right

proc precedence(operator: uint8): int =
  if operator == uint8('^'): return 3
  if operator == uint8('*') or operator == uint8('/'): return 2
  1

proc applyOperator(numbers: var array[MaxOperands, float64], numberCount: var int,
                   operator: uint8): bool =
  if numberCount < 2: return false
  dec numberCount
  let right = numbers[numberCount]
  dec numberCount
  let left = numbers[numberCount]
  var result = 0.0
  case operator
  of uint8('+'): result = left + right
  of uint8('-'): result = left - right
  of uint8('*'): result = left * right
  of uint8('/'):
    if right == 0.0: return false
    result = left / right
  else: result = pow(left, right)
  if result.classify in {fcNan, fcInf, fcNegInf} or abs(result) > MaxIntermediate: return false
  numbers[numberCount] = result
  inc numberCount
  true

proc shunting_yard*(input: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "shunting_yard".} =
  if input == nil or length < 2 or length > MaxInputValues.csize_t: return InvalidResult
  let byteCountValue = input[0]
  if byteCountValue < 1 or byteCountValue > MaxExpressionBytes.int64: return InvalidResult
  let byteCount = int(byteCountValue)
  if length != csize_t(byteCount + 1): return InvalidResult

  var numbers: array[MaxOperands, float64]
  var operators: array[MaxOperators, uint8]
  var numberCount = 0
  var operatorCount = 0
  var operandCount = 0
  var seenOperatorCount = 0
  var position = 0
  var expectNumber = true
  while position < byteCount:
    let raw = input[position + 1]
    if raw < 0 or raw > 127: return InvalidResult
    let character = uint8(raw)
    if character == uint8(' ') or character in 9'u8 .. 13'u8:
      inc position
      continue
    if expectNumber:
      let start = position
      var integerDigits = 0
      var number = 0.0
      while position < byteCount:
        let digit = input[position + 1]
        if digit < 48 or digit > 57: break
        number = roundedAdd(roundedMultiply(number, 10.0), float64(digit - 48))
        inc integerDigits
        inc position
      if integerDigits == 0: return InvalidResult
      if position < byteCount and input[position + 1] == 46:
        inc position
        var fractionDigits = 0
        var scale = 0.1
        while position < byteCount:
          let digit = input[position + 1]
          if digit < 48 or digit > 57: break
          let product = roundedMultiply(float64(digit - 48), scale)
          number = roundedAdd(number, product)
          scale = roundedDivide(scale, 10.0)
          inc fractionDigits
          inc position
        if fractionDigits == 0: return InvalidResult
      if position - start > MaxLiteralBytes or number > MaxLiteralValue or operandCount >= MaxOperands:
        return InvalidResult
      numbers[numberCount] = number
      inc numberCount
      inc operandCount
      expectNumber = false
    else:
      if character notin {uint8('+'), uint8('-'), uint8('*'), uint8('/'), uint8('^')}:
        return InvalidResult
      while operatorCount > 0:
        let top = operators[operatorCount - 1]
        let topPrecedence = precedence(top)
        let currentPrecedence = precedence(character)
        if topPrecedence < currentPrecedence or
            (topPrecedence == currentPrecedence and character == uint8('^')): break
        dec operatorCount
        if not applyOperator(numbers, numberCount, top): return InvalidResult
      if operatorCount >= MaxOperators: return InvalidResult
      operators[operatorCount] = character
      inc operatorCount
      inc seenOperatorCount
      inc position
      expectNumber = true
  if expectNumber or operandCount == 0 or seenOperatorCount + 1 != operandCount:
    return InvalidResult
  while operatorCount > 0:
    dec operatorCount
    if not applyOperator(numbers, numberCount, operators[operatorCount]): return InvalidResult
  if numberCount != 1: return InvalidResult
  numbers[0]
