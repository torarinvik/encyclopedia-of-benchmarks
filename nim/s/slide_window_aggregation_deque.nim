const
  MaxOperations = 32
  MaxInputLength = 162
  Modulus = 97'i64

type Matrix = object
  a, b, c, d: int64

proc identity(): Matrix =
  Matrix(a: 1, b: 0, c: 0, d: 1)

proc multiply(x, y: Matrix): Matrix =
  Matrix(
    a: (x.a * y.a + x.b * y.c) mod Modulus,
    b: (x.a * y.b + x.b * y.d) mod Modulus,
    c: (x.c * y.a + x.d * y.c) mod Modulus,
    d: (x.c * y.b + x.d * y.d) mod Modulus
  )

proc pack(value: Matrix): int64 =
  value.a + Modulus * value.b + Modulus * Modulus * value.c +
    Modulus * Modulus * Modulus * value.d

proc pushFront(items: var array[MaxOperations, Matrix],
               aggregates: var array[MaxOperations, Matrix],
               count: var int, value: Matrix) =
  items[count] = value
  aggregates[count] = if count == 0: value else: multiply(value, aggregates[count - 1])
  inc count

proc pushBack(items: var array[MaxOperations, Matrix],
              aggregates: var array[MaxOperations, Matrix],
              count: var int, value: Matrix) =
  items[count] = value
  aggregates[count] = if count == 0: value else: multiply(aggregates[count - 1], value)
  inc count

proc rebalance(front: var array[MaxOperations, Matrix],
               frontAggregates: var array[MaxOperations, Matrix], frontCount: var int,
               back: var array[MaxOperations, Matrix],
               backAggregates: var array[MaxOperations, Matrix], backCount: var int,
               temporary: var array[MaxOperations, Matrix]) =
  let frontWasEmpty = frontCount == 0
  let total = frontCount + backCount
  for i in 0 ..< frontCount:
    temporary[i] = front[frontCount - 1 - i]
  for i in 0 ..< backCount:
    temporary[frontCount + i] = back[i]
  let frontSize = total div 2 + (if frontWasEmpty: total mod 2 else: 0)
  frontCount = 0
  backCount = 0
  if frontSize > 0:
    for i in countdown(frontSize - 1, 0):
      pushFront(front, frontAggregates, frontCount, temporary[i])
  for i in frontSize ..< total:
    pushBack(back, backAggregates, backCount, temporary[i])

proc slide_window_aggregation_deque*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "slide_window_aggregation_deque".} =
  if input == nil or length < 1 or length > csize_t(MaxInputLength): return -1
  let operationCountValue = input[0]
  if operationCountValue < 0 or operationCountValue > MaxOperations: return -1
  let operationCount = int(operationCountValue)

  var front, frontAggregates, back, backAggregates, temporary: array[MaxOperations, Matrix]
  var frontCount = 0
  var backCount = 0
  var position = 1
  var queryOrdinal = 0'i64
  var checksum = 0'i64

  for _ in 0 ..< operationCount:
    if position >= int(length): return -1
    let opcode = input[position]
    inc position
    if opcode == 0 or opcode == 1:
      if int(length) - position < 4: return -1
      let value = Matrix(a: input[position], b: input[position + 1],
                         c: input[position + 2], d: input[position + 3])
      if value.a < 0 or value.a >= Modulus or value.b < 0 or value.b >= Modulus or
         value.c < 0 or value.c >= Modulus or value.d < 0 or value.d >= Modulus: return -1
      position += 4
      if opcode == 0: pushFront(front, frontAggregates, frontCount, value)
      else: pushBack(back, backAggregates, backCount, value)
    elif opcode == 2 or opcode == 3:
      if frontCount + backCount == 0: return -1
      if opcode == 2:
        if frontCount == 0:
          rebalance(front, frontAggregates, frontCount, back, backAggregates, backCount, temporary)
        dec frontCount
      else:
        if backCount == 0:
          rebalance(front, frontAggregates, frontCount, back, backAggregates, backCount, temporary)
        dec backCount
    elif opcode == 4:
      let left = if frontCount == 0: identity() else: frontAggregates[frontCount - 1]
      let right = if backCount == 0: identity() else: backAggregates[backCount - 1]
      inc queryOrdinal
      checksum += queryOrdinal * (pack(multiply(left, right)) + 1)
    else:
      return -1
  if position != int(length): return -1
  checksum
