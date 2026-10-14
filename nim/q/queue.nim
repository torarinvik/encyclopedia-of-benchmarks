## Bounded ring-buffer queue with a deterministic operation-trace checksum.
proc queue_benchmark*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "queue_benchmark".} =
  if length > 1024 or length mod 2 != 0: return -1
  let operationCount = int(length div 2)
  var dataQueue: array[256, int64]
  var head = 0
  var count = 0
  var checksum: int64 = 0
  for operation in 0 ..< operationCount:
    let opcode = values[2 * operation]
    let payload = values[2 * operation + 1]
    var observed: int64 = 0
    var returnsValue = true
    if opcode == 0:
      if payload < -1000000 or payload > 1000000 or count == 256: return -1
      dataQueue[(head + count) mod 256] = payload
      inc count
      returnsValue = false
    elif opcode == 1:
      if payload != 0 or count == 0: return -1
      observed = dataQueue[head]
      head = (head + 1) mod 256
      dec count
    elif opcode == 2:
      if payload != 0 or count == 0: return -1
      observed = dataQueue[head]
    elif opcode == 3:
      if payload != 0 or count == 0: return -1
      observed = dataQueue[(head + count - 1) mod 256]
    elif opcode == 4:
      if payload != 0: return -1
      observed = if count == 0: 1 else: 0
    elif opcode == 5:
      if payload != 0: return -1
      observed = int64(count)
    else:
      return -1
    if returnsValue: checksum += int64(operation + 1) * (observed + 1000000)
  for index in 0 ..< count:
    checksum += int64(operationCount + index + 1) * (dataQueue[(head + index) mod 256] + 1000000)
  checksum
