proc pkcs7Padding*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "pkcs7_padding".} =
  if input == nil or length < 5 or length > 69: return -1
  let operation = input[0]
  let blockArg = input[1]
  let offsetArg = input[2]
  let dataArg = input[3]
  if operation < 0 or operation > 2 or blockArg < 1 or blockArg > 16 or
      dataArg < 1 or dataArg > 64 or
      (operation == 0 and (offsetArg < 0 or offsetArg > dataArg)) or
      length != csize_t(dataArg) + 4: return -1
  let blockSize = int(blockArg)
  let offset = if operation == 0: int(offsetArg) else: 0
  let dataLength = int(dataArg)
  for index in 0 ..< dataLength:
    let value = input[index + 4]
    if value < 0 or value > 255: return -1

  var paddingCount: int
  var outputLength: int
  if operation == 0:
    paddingCount = blockSize - dataLength mod blockSize
    if offset + paddingCount > dataLength: return -1
    outputLength = dataLength + 1
  elif operation == 1:
    if dataLength mod blockSize != 0: return -1
    paddingCount = int(input[dataLength + 3])
    if paddingCount == 0 or paddingCount > blockSize: return -1
    for index in (dataLength - paddingCount) ..< dataLength:
      if int(input[index + 4]) != paddingCount: return -1
    outputLength = dataLength - paddingCount
  else:
    paddingCount = int(input[dataLength + 3])
    let paddingStart = int32(dataLength - paddingCount)
    let invalidBits = cast[uint32](paddingStart or (int32(paddingCount) - 1))
    var paddingCheckFailed = -int64(invalidBits shr 31)
    for index in 0 ..< dataLength:
      let difference = int32(index) - paddingStart
      let negativeBit = cast[uint32](difference) shr 31
      let mask = -int64(1'u32 - negativeBit)
      let value = int64(input[index + 4])
      paddingCheckFailed = paddingCheckFailed or ((value xor int64(paddingCount)) and mask)
    if paddingCheckFailed != 0: return -1
    outputLength = 1
  if output == nil or outputCapacity < csize_t(outputLength): return -2
  if operation == 0:
    output[0] = uint8(paddingCount)
    for index in 0 ..< dataLength:
      var value = int(input[index + 4])
      if index >= offset and index < offset + paddingCount: value = paddingCount
      output[index + 1] = uint8(value)
  elif operation == 1:
    for index in 0 ..< outputLength: output[index] = uint8(input[index + 4])
  else:
    output[0] = uint8(paddingCount)
  int64(outputLength)
