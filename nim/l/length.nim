const
  MaxPayloadBytes = 256
  MaxInputLength = 259
  OutputBytes = 16

proc utf8ScalarCount(bytes: array[MaxPayloadBytes, uint8], length: int): int =
  var index = 0
  while index < length:
    let lead = bytes[index]
    if lead >= 1'u8 and lead <= 0x7f'u8:
      inc index
    elif lead >= 0xc2'u8 and lead <= 0xdf'u8:
      if index + 1 >= length or bytes[index + 1] < 0x80'u8 or bytes[index + 1] > 0xbf'u8:
        return -1
      index += 2
    elif lead >= 0xe0'u8 and lead <= 0xef'u8:
      if index + 2 >= length: return -1
      let second = bytes[index + 1]
      let third = bytes[index + 2]
      if second < 0x80'u8 or second > 0xbf'u8 or third < 0x80'u8 or third > 0xbf'u8 or
          (lead == 0xe0'u8 and second < 0xa0'u8) or (lead == 0xed'u8 and second > 0x9f'u8):
        return -1
      index += 3
    else:
      return -1
    inc result

proc putI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc length*(input: ptr UncheckedArray[int64], inputLength: csize_t,
             output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "length".} =
  if input == nil or inputLength < 2 or inputLength > csize_t(MaxInputLength): return -1
  if input[0] < 0 or input[0] > int64(MaxPayloadBytes): return -1
  let payloadLength = int(input[0])
  if int(inputLength) != payloadLength + 2: return -1

  var payload: array[MaxPayloadBytes, uint8]
  for index in 0 .. payloadLength:
    let value = input[index + 1]
    if value < 0 or value > 255: return -1
    if index == payloadLength:
      if value != 0: return -1
    else:
      if value == 0: return -1
      payload[index] = uint8(value)
  let scalarCount = utf8ScalarCount(payload, payloadLength)
  if scalarCount < 0: return -1
  if output == nil or outputCapacity < csize_t(OutputBytes): return -2

  putI64Le(output, 0, int64(payloadLength))
  putI64Le(output, 8, int64(scalarCount))
  int64(OutputBytes)
