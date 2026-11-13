const
  QueueCapacity = 16
  MaxOperations = 32
  MaxParseableLength = 65
  ValueMin = -1000'i64
  ValueMax = 1000'i64
  ChecksumOffset = 1001'i64

proc minimum_queue_two_stacks*(input: ptr UncheckedArray[int64],
    length: csize_t): int64 {.cdecl, exportc: "minimum_queue_two_stacks".} =
  if input.isNil or length < csize_t(1) or length > csize_t(MaxParseableLength): return -1
  if input[0] < 0 or input[0] > MaxOperations: return -1

  var inValues: array[QueueCapacity, int64]
  var inMinimums: array[QueueCapacity, int64]
  var outValues: array[QueueCapacity, int64]
  var outMinimums: array[QueueCapacity, int64]
  var inCount = 0
  var outCount = 0
  var cursor = 1
  let operationCount = int(input[0])
  var checksum = 0'i64

  for operation in 0 ..< operationCount:
    if cursor >= int(length): return -1
    let opcode = input[cursor]
    inc cursor
    if opcode == 0:
      if cursor >= int(length): return -1
      let value = input[cursor]
      inc cursor
      if value < ValueMin or value > ValueMax or inCount + outCount >= QueueCapacity: return -1
      inValues[inCount] = value
      if inCount == 0 or value < inMinimums[inCount - 1]:
        inMinimums[inCount] = value
      else:
        inMinimums[inCount] = inMinimums[inCount - 1]
      inc inCount
    elif opcode == 1:
      if inCount + outCount == 0: return -1
      if outCount == 0:
        while inCount > 0:
          dec inCount
          let value = inValues[inCount]
          outValues[outCount] = value
          if outCount == 0 or value < outMinimums[outCount - 1]:
            outMinimums[outCount] = value
          else:
            outMinimums[outCount] = outMinimums[outCount - 1]
          inc outCount
      dec outCount
      checksum += int64(operation + 1) * (outValues[outCount] + ChecksumOffset)
    elif opcode == 2:
      if inCount + outCount == 0: return -1
      var observed: int64
      if inCount == 0:
        observed = outMinimums[outCount - 1]
      elif outCount == 0:
        observed = inMinimums[inCount - 1]
      elif inMinimums[inCount - 1] < outMinimums[outCount - 1]:
        observed = inMinimums[inCount - 1]
      else:
        observed = outMinimums[outCount - 1]
      checksum += int64(operation + 1) * (observed + ChecksumOffset)
    else:
      return -1
  if cursor != int(length): return -1

  var position = 0
  for index in 0 ..< outCount:
    inc position
    checksum += int64(position) * (outValues[outCount - index - 1] + ChecksumOffset)
  for index in 0 ..< inCount:
    inc position
    checksum += int64(position) * (inValues[index] + ChecksumOffset)
  checksum
