const
  MaxOperations = 64
  MaxInputLength = 1 + 3 * MaxOperations
  Modulus = 998_244_353'i64

type
  Affine = object
    a, b: int64
  AggregateQueue = object
    backFunctions: array[MaxOperations, Affine]
    backAggregates: array[MaxOperations, Affine]
    frontAggregates: array[MaxOperations, Affine]
    backSize, frontSize: int

proc compose(first, second: Affine): Affine =
  result.a = (second.a * first.a) mod Modulus
  result.b = (second.a * first.b + second.b) mod Modulus

proc pushBack(queue: var AggregateQueue, a, b: int64) =
  let function = Affine(a: a, b: b)
  queue.backFunctions[queue.backSize] = function
  queue.backAggregates[queue.backSize] = if queue.backSize == 0:
    function else: compose(queue.backAggregates[queue.backSize - 1], function)
  inc queue.backSize

proc transfer(queue: var AggregateQueue) =
  while queue.backSize > 0:
    dec queue.backSize
    let function = queue.backFunctions[queue.backSize]
    queue.frontAggregates[queue.frontSize] = if queue.frontSize == 0:
      function else: compose(function, queue.frontAggregates[queue.frontSize - 1])
    inc queue.frontSize

proc popFront(queue: var AggregateQueue): bool =
  if queue.frontSize == 0: transfer(queue)
  if queue.frontSize == 0: return false
  dec queue.frontSize
  true

proc aggregate(queue: AggregateQueue): Affine =
  result = Affine(a: 1, b: 0)
  if queue.frontSize > 0:
    result = queue.frontAggregates[queue.frontSize - 1]
  if queue.backSize > 0:
    result = if queue.frontSize > 0:
      compose(result, queue.backAggregates[queue.backSize - 1])
    else:
      queue.backAggregates[queue.backSize - 1]

proc queue_operate_all_composite*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "queue_operate_all_composite".} =
  if values == nil or length < 1 or length > csize_t(MaxInputLength): return -1
  let operationValue = values[0]
  if operationValue < 0 or operationValue > int64(MaxOperations): return -1
  let operationCount = int(operationValue)

  var queue: AggregateQueue
  var position = 1
  var checksum = 0'i64
  var queryNumber = 0'i64
  for _ in 0 ..< operationCount:
    if position >= int(length): return -1
    let opcode = values[position]
    inc position
    if opcode == 0:
      if int(length) - position < 2: return -1
      let a = values[position]
      let b = values[position + 1]
      position += 2
      if a < 1 or a >= Modulus or b < 0 or b >= Modulus: return -1
      pushBack(queue, a, b)
    elif opcode == 1:
      if not popFront(queue): return -1
    elif opcode == 2:
      if position >= int(length): return -1
      let x = values[position]
      inc position
      if x < 0 or x >= Modulus: return -1
      let function = aggregate(queue)
      let answer = (function.a * x + function.b) mod Modulus
      inc queryNumber
      checksum += queryNumber * (answer + 1)
    else:
      return -1
  if position != int(length): return -1
  checksum
