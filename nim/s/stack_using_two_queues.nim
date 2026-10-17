const MaxOps = 128

proc pushNew(mainQueue, tempQueue: var array[MaxOps, int64],
    head, tail: var int, value: int64) =
  var tempTail = 0
  tempQueue[tempTail] = value
  inc tempTail
  while head < tail:
    tempQueue[tempTail] = mainQueue[head]
    inc tempTail
    inc head
  head = 0
  tail = tempTail

proc stackUsingTwoQueues*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "stack_using_two_queues".} =
  if input == nil or length < 1 or length > 257: return -1
  if input[0] < 0 or input[0] > MaxOps or length != csize_t(1 + 2 * int(input[0])): return -1
  var qa: array[MaxOps, int64]
  var qb: array[MaxOps, int64]
  var mainIsA = true
  var head = 0
  var tail = 0
  var tags: array[MaxOps, int64]
  var results: array[MaxOps, int64]
  var recordCount = 0
  var position = 1
  for _ in 0 ..< int(input[0]):
    let op = input[position]
    let value = input[position + 1]
    position += 2
    if op == 0:
      if value < int64(low(int32)) or value > int64(high(int32)): return -1
      if mainIsA: pushNew(qa, qb, head, tail, value)
      else: pushNew(qb, qa, head, tail, value)
      mainIsA = not mainIsA
    elif op == 1:
      if value != 0 or head == tail: return -1
      tags[recordCount] = 0
      results[recordCount] = if mainIsA: qa[head] else: qb[head]
      inc recordCount
      inc head
    elif op == 2:
      if value != 0: return -1
      if head == tail:
        tags[recordCount] = 1
        results[recordCount] = 0
      else:
        tags[recordCount] = 0
        results[recordCount] = if mainIsA: qa[head] else: qb[head]
      inc recordCount
    else: return -1
  let byteLength = recordCount * 16
  if output == nil or int(outputCapacity) < byteLength: return -2
  for i in 0 ..< recordCount:
    let words = [tags[i], results[i]]
    for w in 0 ..< 2:
      let bits = cast[uint64](words[w])
      for b in 0 ..< 8:
        output[16 * i + 8 * w + b] = uint8((bits shr (8 * b)) and 255)
  int64(byteLength)
