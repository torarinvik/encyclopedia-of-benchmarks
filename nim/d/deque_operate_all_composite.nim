const
  MaxOperations = 64
  MaxInputLength = 1 + 3 * MaxOperations
  TreeBase = 128
  TreeNodes = 256
  Modulus = 998_244_353'i64

type
  Affine = object
    a, b: int64

proc identity(): Affine =
  Affine(a: 1, b: 0)

proc compose(first, second: Affine): Affine =
  result.a = (second.a * first.a) mod Modulus
  result.b = (second.a * first.b + second.b) mod Modulus

proc update(tree: var array[TreeNodes, Affine], position: int, value: Affine) =
  var node = TreeBase + position
  tree[node] = value
  while node > 1:
    node = node div 2
    tree[node] = compose(tree[node * 2], tree[node * 2 + 1])

proc deque_operate_all_composite*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "deque_operate_all_composite".} =
  if values == nil or length < 1 or length > csize_t(MaxInputLength): return -1
  let operationValue = values[0]
  if operationValue < 0 or operationValue > int64(MaxOperations): return -1
  let operationCount = int(operationValue)

  var tree: array[TreeNodes, Affine]
  for node in 0 ..< TreeNodes:
    tree[node] = identity()
  var head = 64
  var tail = 64
  var position = 1
  var checksum = 0'i64
  var queryNumber = 0'i64

  for _ in 0 ..< operationCount:
    if position >= int(length): return -1
    let opcode = values[position]
    inc position
    if opcode == 0 or opcode == 1:
      if int(length) - position < 2: return -1
      let a = values[position]
      let b = values[position + 1]
      position += 2
      if a < 1 or a >= Modulus or b < 0 or b >= Modulus: return -1
      let function = Affine(a: a, b: b)
      if opcode == 0:
        if head == 0: return -1
        dec head
        update(tree, head, function)
      else:
        if tail == TreeBase: return -1
        update(tree, tail, function)
        inc tail
    elif opcode == 2 or opcode == 3:
      if head == tail: return -1
      if opcode == 2:
        update(tree, head, identity())
        inc head
      else:
        dec tail
        update(tree, tail, identity())
    elif opcode == 4:
      if position >= int(length): return -1
      let x = values[position]
      inc position
      if x < 0 or x >= Modulus: return -1
      let function = tree[1]
      let answer = (function.a * x + function.b) mod Modulus
      inc queryNumber
      checksum += queryNumber * (answer + 1)
    else:
      return -1
  if position != int(length): return -1
  checksum
