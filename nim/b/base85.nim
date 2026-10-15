type
  I64Input = ptr UncheckedArray[int64]
  ByteOutput = ptr UncheckedArray[uint8]

const
  MaxInputValues = 66
  MaxDecodedLength = 52

proc decodeGroup(values: I64Input, start, count: csize_t): int64 =
  var value = 0'i64
  for index in 0 ..< 5:
    var digit = 84'i64
    if csize_t(index) < count:
      let byte = values[start + csize_t(index)]
      if byte < 33 or byte > 117: return -1
      digit = byte - 33
    value = value * 85 + digit
  if value > 4_294_967_295'i64: return -1
  value

proc base85*(values: I64Input, length: csize_t, output: ByteOutput,
             outputCapacity: csize_t): int64 {.cdecl, exportc: "base85".} =
  if values == nil or length < 1 or length > MaxInputValues: return -1
  let mode = values[0]
  let payloadLength = length - 1
  var outputLength = csize_t(0)
  if mode == 0:
    for index in 1 ..< length:
      if values[index] < 0 or values[index] > 255: return -1
    let remainder = payloadLength mod 4
    outputLength = (payloadLength div 4) * 5 + (if remainder == 0: 0 else: remainder + 1)
  elif mode == 1:
    if payloadLength mod 5 == 1: return -1
    var offset = csize_t(0)
    while offset < payloadLength:
      let count = if payloadLength - offset < 5: payloadLength - offset else: csize_t(5)
      if decodeGroup(values, offset + 1, count) < 0: return -1
      outputLength += (if count == 5: 4 else: count - 1)
      offset += count
    if outputLength > MaxDecodedLength: return -1
  else:
    return -1
  if outputCapacity < outputLength or (outputLength != 0 and output == nil): return -2

  var written = csize_t(0)
  if mode == 0:
    var offset = csize_t(0)
    while offset < payloadLength:
      let count = if payloadLength - offset < 4: payloadLength - offset else: csize_t(4)
      var value = 0'u64
      for byte in 0 ..< 4:
        value = value shl 8
        if csize_t(byte) < count: value = value or uint64(values[offset + csize_t(byte) + 1])
      var place = 52_200_625'u64
      for digit in 0 ..< 5:
        let encoded = uint8(value div place + 33)
        value = value mod place
        if count == 4 or csize_t(digit) < count + 1:
          output[written] = encoded
          inc written
        case digit
        of 0: place = 614_125
        of 1: place = 7_225
        of 2: place = 85
        else: place = 1
      offset += 4
  else:
    var offset = csize_t(0)
    while offset < payloadLength:
      let count = if payloadLength - offset < 5: payloadLength - offset else: csize_t(5)
      let value = uint64(decodeGroup(values, offset + 1, count))
      let byteCount = if count == 5: 4 else: count - 1
      for byte in 0 ..< int(byteCount):
        output[written] = uint8((value shr (24 - 8 * byte)) and 255)
        inc written
      offset += count
  int64(written)
