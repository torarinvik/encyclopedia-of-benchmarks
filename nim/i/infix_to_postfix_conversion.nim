## Shunting-yard conversion with right-associative exponentiation.
const MaxExpression = 256
const MaxOutput = 512

proc isOperand(ch: int64): bool =
  (ch >= 48 and ch <= 57) or (ch >= 65 and ch <= 90) or (ch >= 97 and ch <= 122)
proc isOperator(ch: int64): bool = ch in [43'i64, 45, 42, 47, 94]
proc precedence(ch: int64): int64 =
  if ch in [43'i64, 45]: 1 elif ch in [42'i64, 47]: 2 else: 3
proc emitToken(result: var array[MaxOutput, uint8], count: var int, token: uint8) =
  if count > 0:
    result[count] = uint8(' ')
    inc count
  result[count] = token
  inc count

proc infix_to_postfix_conversion*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "infix_to_postfix_conversion".} =
  if input.isNil or length < 1: return -1
  let expressionLength = input[0]
  if expressionLength < 0 or expressionLength > MaxExpression or length != 1 + csize_t(expressionLength): return -1
  var stack: array[MaxExpression, uint8]
  var result: array[MaxOutput, uint8]
  var top = 0
  var count = 0
  var expectOperand = true
  for i in 0 ..< int(expressionLength):
    let ch = input[1 + i]
    if isOperand(ch):
      if not expectOperand: return -1
      emitToken(result, count, uint8(ch))
      expectOperand = false
    elif ch == 40:
      if not expectOperand or top == MaxExpression: return -1
      stack[top] = uint8(ch); inc top
    elif ch == 41:
      if expectOperand: return -1
      while top > 0 and stack[top - 1] != uint8('('):
        dec top; emitToken(result, count, stack[top])
      if top == 0: return -1
      dec top
      expectOperand = false
    elif isOperator(ch):
      if expectOperand: return -1
      while top > 0 and stack[top - 1] != uint8('(') and
          (precedence(ch) < precedence(int64(stack[top - 1])) or
           (precedence(ch) == precedence(int64(stack[top - 1])) and ch != 94)):
        dec top; emitToken(result, count, stack[top])
      if top == MaxExpression: return -1
      stack[top] = uint8(ch); inc top
      expectOperand = true
    else: return -1
  if expressionLength != 0 and expectOperand: return -1
  while top > 0:
    dec top
    if stack[top] == uint8('('): return -1
    emitToken(result, count, stack[top])
  result[count] = 0; inc count
  if output.isNil or outputCapacity < csize_t(count): return -2
  for i in 0 ..< count: output[i] = result[i]
  int64(count)
