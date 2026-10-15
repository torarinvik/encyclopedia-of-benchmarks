const MaxCapacity = 256
const ValueOffset = 1_000_000'i64

proc circular_buffer_benchmark*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "circular_buffer_benchmark".} =
  if values == nil or length < 1 or length > 1025 or (length - 1) mod 2 != 0: return -1
  let capacityValue = values[0]
  if capacityValue < 1 or capacityValue > MaxCapacity: return -1
  let capacity = int(capacityValue)
  let operationCount = int((length - 1) div 2)
  var buffer: array[MaxCapacity, int64]
  var head = 0
  var tail = 0
  var count = 0
  var checksum = 0'i64
  for operation in 0 ..< operationCount:
    let opcode = values[1 + 2 * operation]
    let payload = values[2 + 2 * operation]
    var observed = 0'i64
    if opcode == 0:
      if payload < 0 or payload > ValueOffset: return -1
      observed = int64(count == 0)
      if count == capacity: head = (head + 1) mod capacity else: inc count
      buffer[tail] = payload
      tail = (tail + 1) mod capacity
    elif opcode == 1:
      if payload != 0: return -1
      if count == 0: observed = -1
      else:
        observed = buffer[head]
        head = (head + 1) mod capacity
        dec count
    elif opcode == 2:
      if payload != 0: return -1
      observed = int64(count == 0)
    elif opcode == 3:
      if payload != 0: return -1
      observed = int64(count == capacity)
    elif opcode == 4:
      if payload != 0: return -1
      observed = int64(count)
    else: return -1
    checksum += (int64(operation) + 1) * (observed + ValueOffset)
  for index in 0 ..< count:
    checksum += (int64(operationCount + index) + 1) * (buffer[(head + index) mod capacity] + ValueOffset)
  checksum
