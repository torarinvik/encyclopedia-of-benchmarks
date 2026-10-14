## Encode bytes as uppercase Base16 or decode uppercase Base16 bytes.
proc nibble(byte: int64): int64 =
  if byte >= ord('0') and byte <= ord('9'): return byte - ord('0')
  if byte >= ord('A') and byte <= ord('F'): return byte - ord('A') + 10
  -1
proc base16*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "base16".} =
  if input == nil or length < 1 or length > 65: return -1
  let mode = input[0]
  if mode == 0:
    let count = length - 1
    let outputLength = count * 2
    for i in 1 ..< int(length):
      if input[i] < 0 or input[i] > 255: return -1
    if output == nil and outputLength > 0 or outputCapacity < outputLength: return -2
    for i in 0 ..< int(count):
      let byte = input[i + 1]
      let high = byte div 16
      let low = byte mod 16
      output[2 * i] = uint8(if high < 10: ord('0') + int(high) else: ord('A') + int(high) - 10)
      output[2 * i + 1] = uint8(if low < 10: ord('0') + int(low) else: ord('A') + int(low) - 10)
    return int64(outputLength)
  if mode != 1: return -1
  let encodedLength = length - 1
  if encodedLength mod 2 != 0: return -1
  for i in 1 ..< int(length):
    if nibble(input[i]) < 0: return -1
  let outputLength = encodedLength div 2
  if output == nil and outputLength > 0 or outputCapacity < outputLength: return -2
  for i in 0 ..< int(outputLength):
    output[i] = uint8(nibble(input[1 + 2 * i]) * 16 + nibble(input[2 + 2 * i]))
  int64(outputLength)
