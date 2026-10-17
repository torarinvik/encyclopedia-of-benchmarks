const MaxOps = 256
const MaxInputLength = 514

proc storeI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc element_priority_queue_using_list*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "element_priority_queue_using_list".} =
  if input.isNil or length < 1 or length > csize_t(MaxInputLength): return -1
  let operationCount = input[0]
  if operationCount < 0 or operationCount > MaxOps or int(length) != 1 + 2 * int(operationCount): return -1
  var queue: array[100, int32]
  var queueCount = 0
  var dequeued: array[128, int64]
  var dequeuedCount = 0
  for i in 0 ..< int(operationCount):
    let opcode = input[1 + 2 * i]
    let argument = input[2 + 2 * i]
    if opcode == 0:
      if argument < int64(low(int32)) or argument > int64(high(int32)) or queueCount == 100: return -1
      queue[queueCount] = int32(argument)
      inc queueCount
    elif opcode == 1:
      if argument != 0 or queueCount == 0: return -1
      var minimum = 0
      for j in 1 ..< queueCount:
        if queue[j] < queue[minimum]: minimum = j
      dequeued[dequeuedCount] = int64(queue[minimum])
      inc dequeuedCount
      dec queueCount
      for j in minimum ..< queueCount: queue[j] = queue[j + 1]
    else: return -1
  let outputBytes = dequeuedCount * 8
  if output.isNil or capacity < csize_t(outputBytes): return -2
  for i in 0 ..< dequeuedCount: storeI64(output, i * 8, dequeued[i])
  int64(outputBytes)
