proc reduce(value: uint32): uint16 =
  var remainder = value
  for bit in countdown(31, 16):
    if (remainder and (1'u32 shl bit)) != 0:
      remainder = remainder xor (0x1100b'u32 shl (bit - 16))
  uint16(remainder)

proc rabin_content_defined_chunking*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "rabin_content_defined_chunking".} =
  if input.isNil or length < 1 or length > 65: return -1
  if input[0] < 0 or input[0] > 64: return -1
  let n = int(input[0])
  if length != csize_t(n + 1): return -1
  for i in 0..<n:
    if input[i + 1] < 0 or input[i + 1] > 255: return -1
  var outgoing: array[256, uint16]
  for i in 0..<256: outgoing[i] = reduce(uint32(i) shl 24)
  var fingerprint: uint16 = 0
  var boundaries: array[64, uint8]
  var count = 0
  for i in 0..<n:
    fingerprint = reduce((uint32(fingerprint) shl 8) or uint32(input[i + 1]))
    if i >= 4: fingerprint = fingerprint xor outgoing[int(input[i - 3])]
    if (fingerprint and 7) == 0:
      boundaries[count] = uint8(i + 1)
      inc count
  if n > 0 and (count == 0 or int(boundaries[count - 1]) != n):
    boundaries[count] = uint8(n)
    inc count
  if output.isNil or capacity < csize_t(count): return -2
  for i in 0..<count: output[i] = boundaries[i]
  int64(count)
