## Convert a bounded ASCII infix expression with the source's operator stack.
const MaxExpression = 24
const MaxStack = 10

proc isOperand(ch: int64): bool =
  (ch >= 48 and ch <= 57) or (ch >= 65 and ch <= 90) or (ch >= 97 and ch <= 122)
proc isOperator(ch: int64): bool = ch in [43'i64, 45, 42, 47, 37]
proc precedence(ch: int64): int64 = if ch in [42'i64, 47, 37]: 1 else: 0

proc infix_to_postfix2*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "infix_to_postfix2".} =
  if input.isNil or length == 0 or length > csize_t(MaxExpression): return -1
  var stack: array[MaxStack, uint8]
  var result: array[MaxExpression + 1, uint8]
  var top = 0
  var count = 0
  var expectOperand = true
  for index in 0 ..< int(length):
    let ch = input[index]
    if isOperand(ch):
      if not expectOperand: return -1
      result[count] = uint8(ch); inc count; expectOperand = false
    elif ch == 40:
      if not expectOperand or top == MaxStack: return -1
      stack[top] = uint8(ch); inc top
    elif ch == 41:
      if expectOperand: return -1
      while top > 0 and stack[top - 1] != uint8('('):
        dec top; result[count] = stack[top]; inc count
      if top == 0: return -1
      dec top; expectOperand = false
    elif isOperator(ch):
      if expectOperand: return -1
      while top > 0 and stack[top - 1] != uint8('(') and precedence(ch) <= precedence(int64(stack[top - 1])):
        dec top; result[count] = stack[top]; inc count
      if top == MaxStack: return -1
      stack[top] = uint8(ch); inc top; expectOperand = true
    else: return -1
  if expectOperand: return -1
  while top > 0:
    dec top
    if stack[top] == uint8('('): return -1
    result[count] = stack[top]; inc count
  result[count] = 0; inc count
  if output.isNil or outputCapacity < csize_t(count): return -2
  for index in 0 ..< count: output[index] = result[index]
  int64(count)
