## Clean-room bounded declarator parser; no upstream source text is copied.
const MaxInput = 96
const MaxName = 16
const MaxOps = 12
const MaxDepth = 6
const MaxParams = 3
const MaxOutput = 128
const OpPointer = 1
const OpArray = 2
const OpFunction = 3
const TypeChar = 1
const TypeInt = 2
const TypeFloat = 3
const TypeDouble = 4
const TypeVoid = 5

type
  Op = object
    kind, value, argc: int
    paramType: array[MaxParams, int]
    paramPtrs: array[MaxParams, int]
  Parser = object
    input: ptr UncheckedArray[int64]
    length, pos: int

proc skipSpace(p: var Parser) =
  while p.pos < p.length:
    let c = int(p.input[p.pos])
    if c != ord(' ') and c != 9 and c != 10 and c != 13: break
    inc p.pos

proc peek(p: var Parser): int =
  p.skipSpace()
  if p.pos < p.length: int(p.input[p.pos]) else: -1

proc consume(p: var Parser, wanted: int): bool =
  if p.peek() != wanted: return false
  inc p.pos
  true

proc isWordStart(c: int): bool =
  (c >= ord('A') and c <= ord('Z')) or (c >= ord('a') and c <= ord('z')) or c == ord('_')

proc isWordPart(c: int): bool =
  isWordStart(c) or (c >= ord('0') and c <= ord('9'))

proc readWord(p: var Parser, outWord: var array[MaxName + 1, char]): int =
  var c = p.peek()
  if not isWordStart(c): return 0
  var used = 0
  while p.pos < p.length and isWordPart(int(p.input[p.pos])):
    c = int(p.input[p.pos])
    if used >= MaxName: return 0
    outWord[used] = char(c)
    inc used
    inc p.pos
    c = p.peek()
  outWord[used] = '\0'
  used

proc wordIs(token: array[MaxName + 1, char], n: int, value: string): bool =
  if n != value.len: return false
  for i in 0..<n:
    if token[i] != value[i]: return false
  true

proc baseType(p: var Parser): int =
  var token: array[MaxName + 1, char]
  let n = readWord(p, token)
  if wordIs(token, n, "char"): TypeChar
  elif wordIs(token, n, "int"): TypeInt
  elif wordIs(token, n, "float"): TypeFloat
  elif wordIs(token, n, "double"): TypeDouble
  elif wordIs(token, n, "void"): TypeVoid
  else: 0

proc decimal(p: var Parser, value: var int): bool =
  var c = p.peek()
  if c < ord('0') or c > ord('9'): return false
  var result = 0
  while p.pos < p.length and int(p.input[p.pos]) >= ord('0') and int(p.input[p.pos]) <= ord('9'):
    c = int(p.input[p.pos])
    result = result * 10 + c - ord('0')
    if result > 99: return false
    inc p.pos
    c = p.peek()
  if result < 1: return false
  value = result
  true

proc appendOp(ops: var array[MaxOps, Op], count: var int, item: Op): bool =
  if count >= MaxOps: return false
  ops[count] = item
  inc count
  true

proc parseParams(p: var Parser, item: var Op): bool =
  item.argc = 0
  if not p.consume(ord('(')): return false
  if p.consume(ord(')')): return true
  while true:
    if item.argc >= MaxParams: return false
    let t = baseType(p)
    if t == 0: return false
    var stars = 0
    while p.consume(ord('*')):
      inc stars
      if stars > 8: return false
    item.paramType[item.argc] = t
    item.paramPtrs[item.argc] = stars
    inc item.argc
    if p.consume(ord(')')): break
    if not p.consume(ord(',')): return false
  if item.argc == 1 and item.paramType[0] == TypeVoid and item.paramPtrs[0] == 0:
    item.argc = 0
  else:
    for a in 0..<item.argc:
      if item.paramType[a] == TypeVoid and item.paramPtrs[a] == 0: return false
  true

proc parseDeclarator(p: var Parser, name: var array[MaxName + 1, char],
                     ops: var array[MaxOps, Op], count: var int, depth: int): bool =
  if depth > MaxDepth: return false
  var stars = 0
  while p.consume(ord('*')):
    inc stars
    if stars > 8: return false
  if p.consume(ord('(')):
    if not parseDeclarator(p, name, ops, count, depth + 1) or not p.consume(ord(')')): return false
  else:
    if name[0] != '\0' or readWord(p, name) == 0: return false
  while true:
    let c = p.peek()
    if c == ord('['):
      var item = Op(kind: OpArray)
      if not p.consume(ord('[')) or not decimal(p, item.value) or not p.consume(ord(']')) or not appendOp(ops, count, item): return false
    elif c == ord('('):
      var item = Op(kind: OpFunction)
      if not parseParams(p, item) or not appendOp(ops, count, item): return false
    else: break
  while stars > 0:
    if not appendOp(ops, count, Op(kind: OpPointer)): return false
    dec stars
  true

proc validOrder(base: int, ops: array[MaxOps, Op], count: int): bool =
  var current = 0
  var isVoid = base == TypeVoid
  for i in countdown(count - 1, 0):
    if ops[i].kind == OpArray:
      if current == 3 or (current == 0 and isVoid): return false
      current = 2
      isVoid = false
    elif ops[i].kind == OpFunction:
      if current == 2 or current == 3: return false
      current = 3
      isVoid = false
    elif ops[i].kind == OpPointer:
      current = 1
      isVoid = false
    else: return false
  true

proc prolangs_c_cdecl*(input: ptr UncheckedArray[int64], inputLength: csize_t,
                       output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
                       {.cdecl, exportc: "prolangs_c_cdecl".} =
  if input == nil or inputLength < 1 or inputLength > MaxInput: return -1
  let length = int(inputLength)
  for i in 0..<length:
    if input[i] <= 0 or input[i] > 127: return -1
  var p = Parser(input: input, length: length)
  let base = baseType(p)
  var name: array[MaxName + 1, char]
  var ops: array[MaxOps, Op]
  var count = 0
  if base == 0 or not parseDeclarator(p, name, ops, count, 0) or not validOrder(base, ops, count) or (base == TypeVoid and count == 0) or p.peek() != -1: return -1
  var nameLength = 0
  while nameLength < MaxName and name[nameLength] != '\0': inc nameLength
  if wordIs(name, nameLength, "char") or wordIs(name, nameLength, "int") or wordIs(name, nameLength, "float") or wordIs(name, nameLength, "double") or wordIs(name, nameLength, "void"): return -1
  var encoded: array[MaxOutput, uint8]
  var used = 0
  encoded[used] = uint8(base); inc used
  encoded[used] = uint8(nameLength); inc used
  for i in 0..<nameLength:
    encoded[used] = uint8(ord(name[i])); inc used
  encoded[used] = uint8(count); inc used
  for i in 0..<count:
    encoded[used] = uint8(ops[i].kind); inc used
    if ops[i].kind == OpArray:
      encoded[used] = uint8(ops[i].value); inc used
    elif ops[i].kind == OpFunction:
      encoded[used] = uint8(ops[i].argc); inc used
      for a in 0..<ops[i].argc:
        encoded[used] = uint8(ops[i].paramType[a]); inc used
        encoded[used] = uint8(ops[i].paramPtrs[a]); inc used
  if output == nil or outputCapacity < csize_t(used): return -2
  for i in 0..<used: output[i] = encoded[i]
  int64(used)
