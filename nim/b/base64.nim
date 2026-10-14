## Encode and decode bytes with the RFC 4648 Base64 alphabet.
proc base64Value(byte: int64): int64 =
  if byte >= ord('A') and byte <= ord('Z'): return byte - ord('A')
  if byte >= ord('a') and byte <= ord('z'): return byte - ord('a') + 26
  if byte >= ord('0') and byte <= ord('9'): return byte - ord('0') + 52
  if byte == ord('+'): return 62
  if byte == ord('/'): return 63
  -1

proc base64*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "base64".} =
  if input == nil or length < 1 or length > 66: return -1
  let mode = input[0]
  if mode == 0:
    let count = int(length - 1)
    for i in 1 ..< int(length):
      if input[i] < 0 or input[i] > 255: return -1
    let outputLength = if count == 0: 0 else: ((count + 2) div 3) * 4
    let symbols = (count * 8 + 5) div 6
    if (output == nil and outputLength > 0) or outputCapacity < csize_t(outputLength): return -2
    for i in 0 ..< outputLength:
      if i >= symbols:
        output[i] = uint8(ord('='))
      else:
        var value = 0
        for bit in i * 6 ..< i * 6 + 6:
          value = value shl 1
          if bit < count * 8:
            let byte = int(input[1 + bit div 8])
            value = value or ((byte shr (7 - bit mod 8)) and 1)
        output[i] = uint8(ord("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"[value]))
    return int64(outputLength)
  if mode != 1: return -1
  let encodedLength = int(length - 1)
  var contentLength = encodedLength
  for i in 0 ..< encodedLength:
    if input[i + 1] == ord('='):
      contentLength = i
      break
  let padding = encodedLength - contentLength
  for i in 0 ..< contentLength:
    if base64Value(input[i + 1]) < 0: return -1
  for i in contentLength ..< encodedLength:
    if input[i + 1] != ord('='): return -1
  let remainder = contentLength mod 4
  var expectedPadding = 0
  case remainder
  of 0: expectedPadding = 0
  of 2: expectedPadding = 2
  of 3: expectedPadding = 1
  else: return -1
  if padding != 0 and (encodedLength mod 4 != 0 or padding != expectedPadding): return -1
  if contentLength > 0 and remainder != 0:
    let finalValue = int(base64Value(input[contentLength]))
    let unused = if remainder == 2: 4 else: 2
    if (finalValue and ((1 shl unused) - 1)) != 0: return -1
  let outputLength = contentLength * 6 div 8
  if (output == nil and outputLength > 0) or outputCapacity < csize_t(outputLength): return -2
  for i in 0 ..< outputLength:
    var byte = 0
    for bit in i * 8 ..< i * 8 + 8:
      let symbol = int(base64Value(input[1 + bit div 6]))
      byte = (byte shl 1) or ((symbol shr (5 - bit mod 6)) and 1)
    output[i] = uint8(byte)
  int64(outputLength)
