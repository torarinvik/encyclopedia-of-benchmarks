const
  MaxN = 256
  MaxQ = 256
  MaxBase = 256
  MaxTree = 2 * MaxBase
  MaxParseableInput = 2 + MaxN + 5 * MaxQ + 1
  MaxOutputBytes = 8 * MaxQ
  Modulus = 998244353'i64

type
  Operation = object
    kind, left, right, multiplier, offset: int64

proc applyTag(mul, add: var array[MaxTree, int64], node: int,
              multiplier, offset: int64) =
  add[node] = (multiplier * add[node] + offset) mod Modulus
  mul[node] = (multiplier * mul[node]) mod Modulus

proc push(mul, add: var array[MaxTree, int64], node: int) =
  if mul[node] != 1 or add[node] != 0:
    applyTag(mul, add, 2 * node, mul[node], add[node])
    applyTag(mul, add, 2 * node + 1, mul[node], add[node])
    mul[node] = 1
    add[node] = 0

proc rangeApply(mul, add: var array[MaxTree, int64], node, segmentLeft,
                segmentRight, left, right: int, multiplier, offset: int64) =
  if right <= segmentLeft or segmentRight <= left: return
  if left <= segmentLeft and segmentRight <= right:
    applyTag(mul, add, node, multiplier, offset)
    return
  push(mul, add, node)
  let middle = segmentLeft + (segmentRight - segmentLeft) div 2
  rangeApply(mul, add, 2 * node, segmentLeft, middle, left, right, multiplier, offset)
  rangeApply(mul, add, 2 * node + 1, middle, segmentRight, left, right, multiplier, offset)

proc pointGet(mul, add: var array[MaxTree, int64], initial: openArray[int64],
              node, segmentLeft, segmentRight, index: int): int64 =
  if segmentRight - segmentLeft == 1:
    return (mul[node] * initial[index] + add[node]) mod Modulus
  push(mul, add, node)
  let middle = segmentLeft + (segmentRight - segmentLeft) div 2
  if index < middle:
    return pointGet(mul, add, initial, 2 * node, segmentLeft, middle, index)
  pointGet(mul, add, initial, 2 * node + 1, middle, segmentRight, index)

proc putI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc range_affine_point_get*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "range_affine_point_get".} =
  if input.isNil or length < 2 or length > csize_t(MaxParseableInput): return -1
  let nValue = input[0]
  let qValue = input[1]
  if nValue < 1 or nValue > MaxN or qValue < 0 or qValue > MaxQ: return -1
  let n = int(nValue)
  let q = int(qValue)
  if 2 + n > int(length): return -1
  var initial: array[MaxN, int64]
  var operations: array[MaxQ, Operation]
  for index in 0 ..< n:
    initial[index] = input[2 + index]
    if initial[index] < 0 or initial[index] >= Modulus: return -1
  var cursor = 2 + n
  var queryCount = 0
  for index in 0 ..< q:
    if cursor >= int(length): return -1
    let kind = input[cursor]
    inc cursor
    if kind == 0:
      if cursor + 4 > int(length): return -1
      let left = input[cursor]
      let right = input[cursor + 1]
      let multiplier = input[cursor + 2]
      let offset = input[cursor + 3]
      cursor += 4
      if left < 0 or left >= right or right > nValue or
          multiplier < 1 or multiplier >= Modulus or offset < 0 or offset >= Modulus: return -1
      operations[index] = Operation(kind: kind, left: left, right: right,
        multiplier: multiplier, offset: offset)
    elif kind == 1:
      if cursor >= int(length): return -1
      let point = input[cursor]
      inc cursor
      if point < 0 or point >= nValue: return -1
      operations[index] = Operation(kind: kind, left: point)
      inc queryCount
    else: return -1
  if cursor != int(length): return -1
  let outputBytes = 8 * queryCount
  if outputBytes > 0 and (output.isNil or capacity < csize_t(outputBytes)): return -2

  var base = 1
  while base < n: base *= 2
  var mul: array[MaxTree, int64]
  var add: array[MaxTree, int64]
  for node in 0 ..< MaxTree: mul[node] = 1
  var answer = 0
  for index in 0 ..< q:
    let operation = operations[index]
    if operation.kind == 0:
      rangeApply(mul, add, 1, 0, base, int(operation.left), int(operation.right),
        operation.multiplier, operation.offset)
    else:
      let value = pointGet(mul, add, initial, 1, 0, base, int(operation.left))
      putI64Le(output, 8 * answer, value)
      inc answer
  int64(outputBytes)
