const
  MaxLength = 256
  Polynomial = 0x04c11db7'u64
  OutputMask = 0xffffffff'u64

proc netbench_crc*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "netbench_crc".} =
  if length > MaxLength or (length != 0 and values.isNil): return -1
  for index in 0 ..< int(length):
    if values[index] < 0 or values[index] > 255: return -1

  var table: array[256, uint64]
  for byte in 0 ..< 256:
    var remainder = uint64(byte) shl 24
    for bit in 0 ..< 8:
      if (remainder and 0x80000000'u64) != 0:
        remainder = (remainder shl 1) xor Polynomial
      else:
        remainder = remainder shl 1
    table[byte] = remainder

  var crc = 0'u64
  for index in 0 ..< int(length):
    let byte = uint64(values[index])
    let tableIndex = int(((crc shr 24) xor byte) and 0xff'u64)
    crc = (crc shl 8) xor table[tableIndex]
  int64(crc and OutputMask)
