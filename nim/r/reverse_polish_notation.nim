const
  MaxInputLength = 255
  MaxParseableInputLength = 256
  MaxTokenCount = 63
  MaxOperandMagnitude = 1_000_000'i64
  MaxIntermediateMagnitude = 1.0e200
  InvalidResult = -1.0e300

proc reverse_polish_notation*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "reverse_polish_notation".} =
  if values.isNil or length < 1 or length > csize_t(MaxParseableInputLength):
    return InvalidResult
  if length > csize_t(MaxInputLength): return InvalidResult
  let inputLength = int(length)
  for index in 0 ..< inputLength:
    if values[index] < 0 or values[index] > 127: return InvalidResult

  var stack: array[MaxTokenCount, float64]
  var top = 0
  var position = 0
  var tokenCount = 0
  while position < inputLength:
    let tokenStart = position
    while position < inputLength and values[position] != 32:
      inc position
    let tokenLength = position - tokenStart
    if tokenLength == 0: return InvalidResult
    inc tokenCount
    if tokenCount > MaxTokenCount: return InvalidResult

    let token = values[tokenStart]
    let isOperator = tokenLength == 1 and
      (token == 43 or token == 45 or token == 42 or token == 47)
    if isOperator:
      if top < 2: return InvalidResult
      let a = stack[top - 1]
      let b = stack[top - 2]
      var result: float64
      if token == 43: result = a + b
      elif token == 45: result = a - b
      elif token == 42: result = a * b
      else:
        if a == 0.0: return InvalidResult
        result = b / a
      if result != result or result < -MaxIntermediateMagnitude or
          result > MaxIntermediateMagnitude: return InvalidResult
      stack[top - 2] = result
      dec top
    else:
      var numberPosition = tokenStart
      var negative = false
      if values[numberPosition] == 43 or values[numberPosition] == 45:
        negative = values[numberPosition] == 45
        inc numberPosition
      if numberPosition == position: return InvalidResult

      var magnitude = 0'i64
      while numberPosition < position:
        let byte = values[numberPosition]
        inc numberPosition
        if byte < 48 or byte > 57: return InvalidResult
        let digit = byte - 48
        if magnitude > (MaxOperandMagnitude - digit) div 10: return InvalidResult
        magnitude = magnitude * 10 + digit
      if top >= MaxTokenCount: return InvalidResult
      var value = float64(magnitude)
      if negative: value = -value
      stack[top] = value
      inc top

    if position < inputLength:
      inc position
      if position == inputLength or values[position] == 32: return InvalidResult

  if tokenCount == 0 or top != 1: return InvalidResult
  let result = stack[0]
  if result != result or result < -MaxIntermediateMagnitude or
      result > MaxIntermediateMagnitude: return InvalidResult
  result
