const MaxBytes = 62
const MaxTokens = 31
const Invalid = -1e300
proc isOp(c: uint8): bool = c == uint8('+') or c == uint8('-') or c == uint8('*') or c == uint8('/')
proc prefix_evaluation*(v: ptr UncheckedArray[int64], n: csize_t): float64 {.cdecl, exportc: "prefix_evaluation".} =
  if v.isNil or n < 2 or n > MaxBytes + 1 or v[0] < 1 or v[0] > MaxBytes or n != csize_t(v[0] + 1): return Invalid
  var tokens: array[MaxTokens, uint8]
  var count = 0
  var need = true
  for i in 1 ..< int(n):
    if v[i] < 0 or v[i] > 127: return Invalid
    let c = uint8(v[i])
    if c == uint8(' '):
      if need: return Invalid
      need = true
      continue
    if not (isOp(c) or (c >= uint8('0') and c <= uint8('9'))) or not need or count >= MaxTokens: return Invalid
    tokens[count] = c
    inc count
    need = false
  if need or count == 0: return Invalid
  var stack: array[MaxTokens, float64]
  var top = 0
  for i in countdown(count - 1, 0):
    let c = tokens[i]
    if c >= uint8('0') and c <= uint8('9'):
      stack[top] = float64(c - uint8('0'))
      inc top
      continue
    if top < 2: return Invalid
    dec top
    let a = stack[top]
    dec top
    let b = stack[top]
    if c == uint8('+'): stack[top] = a + b
    elif c == uint8('-'): stack[top] = a - b
    elif c == uint8('*'): stack[top] = a * b
    else:
      if b == 0: return Invalid
      stack[top] = a / b
    inc top
  if top == 1: return stack[0]
  Invalid
