## Encode and decode bytes with the RFC 4648 Base32 alphabet.
proc base32Value(byte: int64): int64 =
  if byte >= ord('A') and byte <= ord('Z'): return byte - ord('A')
  if byte >= ord('2') and byte <= ord('7'): return byte - ord('2') + 26
  -1

proc base32*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "base32".} =
  if input == nil or length < 1 or length > 66: return -1
  let mode = input[0]
  if mode == 0:
    let count = length - 1
    for i in 1 ..< int(length):
      if input[i] < 0 or input[i] > 255: return -1
    var outputLength: csize_t = 0
    if count > 0: outputLength = ((count + 4) div 5) * 8
    if (output == nil and outputLength > 0) or outputCapacity < outputLength: return -2
    var written = 0
    var start = 0
    while start < int(count):
      let bytes = min(5, int(count) - start)
      let bits = bytes * 8
      let symbols = (bits + 4) div 5
      for symbol in 0 ..< 8:
        if symbol >= symbols:
          output[written] = uint8(ord('='))
        else:
          var value = 0
          for bit in symbol * 5 ..< symbol * 5 + 5:
            value = value shl 1
            if bit < bits:
              let byte = int(input[1 + start + bit div 8])
              value = value or ((byte shr (7 - bit mod 8)) and 1)
          output[written] = uint8(ord("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"[value]))
        inc written
      start += 5
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
    if base32Value(input[i + 1]) < 0: return -1
  for i in contentLength ..< encodedLength:
    if input[i + 1] != ord('='): return -1
  let remainder = contentLength mod 8
  var expectedPadding = 0
  case remainder
  of 0: expectedPadding = 0
  of 2: expectedPadding = 6
  of 4: expectedPadding = 4
  of 5: expectedPadding = 3
  of 7: expectedPadding = 1
  else: return -1
  if padding != 0 and (encodedLength mod 8 != 0 or padding != expectedPadding): return -1
  if contentLength > 0 and remainder != 0:
    let finalValue = int(base32Value(input[contentLength]))
    let unused = if remainder == 2: 2 elif remainder == 4: 4 elif remainder == 5: 1 else: 3
    if (finalValue and ((1 shl unused) - 1)) != 0: return -1
  let outputLength = contentLength * 5 div 8
  if (output == nil and outputLength > 0) or outputCapacity < csize_t(outputLength): return -2
  for i in 0 ..< outputLength:
    var byte = 0
    for bit in i * 8 ..< i * 8 + 8:
      let symbol = int(base32Value(input[1 + bit div 5]))
      byte = (byte shl 1) or ((symbol shr (4 - bit mod 5)) and 1)
    output[i] = uint8(byte)
  int64(outputLength)
