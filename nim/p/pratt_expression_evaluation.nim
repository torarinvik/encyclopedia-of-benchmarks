## Pratt binding-power parser for a bounded integer token grammar.
const InvalidResult = low(int64)
const MaxTokens = 15

type PrattParser = object
  values: ptr UncheckedArray[int64]
  count: int
  position: int
  invalid: bool

proc parseExpression(parser: var PrattParser, minimumBindingPower: int64): int64 =
  if parser.position >= parser.count:
    parser.invalid = true
    return 0
  let offset = 1 + 2 * parser.position
  inc parser.position
  let kind = parser.values[offset]
  var left: int64
  case kind
  of 1:
    left = parser.values[offset + 1]
  of 3:
    left = -parseExpression(parser, 25)
  of 5:
    left = parseExpression(parser, 0)
    if parser.invalid or parser.position >= parser.count or
        parser.values[1 + 2 * parser.position] != 6:
      parser.invalid = true
      return 0
    inc parser.position
  else:
    parser.invalid = true
    return 0
  if parser.invalid: return 0

  while parser.position < parser.count:
    let operator = parser.values[1 + 2 * parser.position]
    var bindingPower = -1'i64
    if operator == 2 or operator == 3: bindingPower = 10
    elif operator == 4: bindingPower = 20
    if bindingPower < minimumBindingPower: break
    inc parser.position
    let right = parseExpression(parser, bindingPower + 1)
    if parser.invalid: return 0
    case operator
    of 2: left += right
    of 3: left -= right
    else: left *= right
  left

proc pratt_expression_evaluation*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "pratt_expression_evaluation".} =
  if input == nil or length < 1 or length > 32: return InvalidResult
  let countValue = input[0]
  if countValue < 1 or countValue > MaxTokens: return InvalidResult
  let count = int(countValue)
  if int(length) != 1 + 2 * count: return InvalidResult
  for token in 0 ..< count:
    let kind = input[1 + 2 * token]
    let payload = input[2 + 2 * token]
    if kind == 1:
      if payload < 0 or payload > 9: return InvalidResult
    elif kind >= 2 and kind <= 6:
      if payload != 0: return InvalidResult
    else:
      return InvalidResult
  var parser = PrattParser(values: input, count: count, position: 0, invalid: false)
  let result = parseExpression(parser, 0)
  if parser.invalid or parser.position != count: return InvalidResult
  result
