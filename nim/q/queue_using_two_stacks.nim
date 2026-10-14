## Amortized FIFO queue implemented with an input and an output stack.
proc queue_using_two_stacks_benchmark*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "queue_using_two_stacks_benchmark".} =
  if length > 1024 or length mod 2 != 0: return -1
  let operationCount = int(length div 2)
  var inStack: array[256, int64]
  var outStack: array[256, int64]
  var inCount = 0
  var outCount = 0
  var checksum: int64 = 0
  for operation in 0 ..< operationCount:
    let opcode = values[2 * operation]
    let payload = values[2 * operation + 1]
    var observed: int64 = 0
    var returnsValue = true
    if opcode == 0:
      if payload < -1000000 or payload > 1000000 or inCount + outCount == 256: return -1
      inStack[inCount] = payload
      inc inCount
      returnsValue = false
    elif opcode == 1 or opcode == 2:
      if payload != 0: return -1
      if outCount == 0:
        while inCount > 0:
          dec inCount
          outStack[outCount] = inStack[inCount]
          inc outCount
      if outCount == 0: return -1
      if opcode == 1:
        dec outCount
        observed = outStack[outCount]
      else:
        observed = outStack[outCount - 1]
    elif opcode == 3:
      if payload != 0: return -1
      observed = int64(inCount + outCount == 0)
    elif opcode == 4:
      if payload != 0: return -1
      observed = int64(inCount + outCount)
    else:
      return -1
    if returnsValue: checksum += int64(operation + 1) * (observed + 1000000)
  for index in 0 ..< outCount:
    checksum += int64(operationCount + index + 1) * (outStack[outCount - index - 1] + 1000000)
  for index in 0 ..< inCount:
    checksum += int64(operationCount + outCount + index + 1) * (inStack[index] + 1000000)
  checksum
