const
  MaxCapacity = 128
  MaxOperations = 256
  MaxInputValues = 515
  MaxOutputBytes = 4096

type
  I64Array = ptr UncheckedArray[int64]
  ByteArray = ptr UncheckedArray[uint8]
  HeapArray = array[MaxCapacity + 1, int32]

proc storeI64Le(output: ByteArray, offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc priority_queues*(input: I64Array, length: csize_t, output: ByteArray,
    outputCapacity: csize_t): int64 {.cdecl, exportc: "priority_queues".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputValues): return -1
  let capacityValue = input[0]
  let operationCountValue = input[1]
  if capacityValue < 1 or capacityValue > MaxCapacity or
      operationCountValue < 0 or operationCountValue > MaxOperations: return -1

  let capacity = int(capacityValue)
  let operationCount = int(operationCountValue)
  if length != csize_t(2 + 2 * operationCount): return -1
  for operation in 0 ..< operationCount:
    let opcode = input[2 + 2 * operation]
    let argument = input[3 + 2 * operation]
    if opcode < 0 or opcode > 5: return -1
    if opcode == 0:
      if argument < int64(low(int32)) or argument > int64(high(int32)): return -1
    elif argument != 0:
      return -1

  if operationCount == 0: return 0
  let needed = operationCount * 16
  if needed > MaxOutputBytes or output.isNil or outputCapacity < csize_t(needed): return -2

  var heap: HeapArray
  var size = 0
  for operation in 0 ..< operationCount:
    let opcode = input[2 + 2 * operation]
    let argument = input[3 + 2 * operation]
    var status = 0'i64
    var value = 0'i64

    if opcode == 0:
      if size == capacity:
        status = 1
      else:
        inc size
        heap[size] = int32(argument)
        var index = size
        while index > 1 and heap[index div 2] < heap[index]:
          swap(heap[index div 2], heap[index])
          index = index div 2
    elif opcode == 1:
      if size == 0:
        status = 2
      else:
        value = int64(heap[1])
        heap[1] = heap[size]
        heap[size] = 0
        dec size
        var index = 1
        while index * 2 <= size:
          var child = index * 2
          if child < size and heap[child + 1] > heap[child]: inc child
          if heap[index] >= heap[child]: break
          swap(heap[index], heap[child])
          index = child
    elif opcode == 2:
      value = if size == 0: 0'i64 else: int64(heap[1])
    elif opcode == 3:
      value = if size == 0: 1'i64 else: 0'i64
    elif opcode == 4:
      value = if size == capacity: 1'i64 else: 0'i64
    else:
      value = int64(size)

    storeI64Le(output, operation * 16, status)
    storeI64Le(output, operation * 16 + 8, value)
  int64(needed)
