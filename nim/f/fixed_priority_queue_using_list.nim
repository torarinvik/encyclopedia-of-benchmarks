const MaxOps = 256
const MaxInputLength = 770

proc storeI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc fixed_priority_queue_using_list*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "fixed_priority_queue_using_list".} =
  if input.isNil or length < 1 or length > csize_t(MaxInputLength): return -1
  let operationCount = input[0]
  if operationCount < 0 or operationCount > MaxOps or int(length) != 1 + 3 * int(operationCount): return -1
  var buckets: array[3, array[100, int32]]
  var counts: array[3, int]
  var dequeued: array[128, int64]
  var dequeuedCount = 0
  for i in 0 ..< int(operationCount):
    let opcode = input[1 + 3 * i]
    let priority = input[2 + 3 * i]
    let data = input[3 + 3 * i]
    if opcode == 0:
      if priority < -3 or priority > 2 or data < int64(low(int32)) or data > int64(high(int32)): return -1
      let bucket = int(if priority < 0: priority + 3 else: priority)
      if counts[bucket] == 100: return -1
      buckets[bucket][counts[bucket]] = int32(data)
      inc counts[bucket]
    elif opcode == 1:
      if priority != 0 or data != 0: return -1
      var bucket = 0
      while bucket < 3 and counts[bucket] == 0: inc bucket
      if bucket == 3: return -1
      dequeued[dequeuedCount] = int64(buckets[bucket][0])
      inc dequeuedCount
      dec counts[bucket]
      for j in 0 ..< counts[bucket]: buckets[bucket][j] = buckets[bucket][j + 1]
    else: return -1
  let outputBytes = dequeuedCount * 8
  if output.isNil or capacity < csize_t(outputBytes): return -2
  for i in 0 ..< dequeuedCount: storeI64(output, i * 8, dequeued[i])
  int64(outputBytes)
