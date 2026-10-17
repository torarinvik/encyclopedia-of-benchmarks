const
  MaxStringLength = 256
  MaxParseableInputLength = 259

proc string_left_rotation*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "string_left_rotation".} =
  if input.isNil or length < 2 or length > csize_t(MaxParseableInputLength): return -1
  let rawLength = input[0]
  let rawRotation = input[1]
  if rawLength < 0 or rawLength > MaxStringLength or rawRotation < 0 or rawRotation > rawLength: return -1
  let textLength = int(rawLength)
  if int(length) != textLength + 2: return -1
  var units: array[MaxStringLength, uint16]
  for i in 0 ..< textLength:
    if input[i + 2] < 0 or input[i + 2] > 65535: return -1
    units[i] = uint16(input[i + 2])
  let required = textLength * 2
  if required == 0: return 0
  if output.isNil or capacity < csize_t(required): return -2
  let rotation = int(rawRotation)
  for i in 0 ..< textLength:
    var source = rotation + i
    if source >= textLength: source -= textLength
    let value = units[source]
    output[2 * i] = uint8(value and 0xff'u16)
    output[2 * i + 1] = uint8(value shr 8)
  int64(required)
