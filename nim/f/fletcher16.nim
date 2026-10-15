## Fletcher-16 checksum for bounded ASCII byte arrays.
const MaxBytes = 4096

proc fletcher16*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "fletcher16".} =
  if length > csize_t(MaxBytes) or (length != 0 and input == nil): return -1
  var sum1 = 0'u32
  var sum2 = 0'u32
  for index in 0 ..< int(length):
    let byte = input[index]
    if byte < 0 or byte > 127: return -1
    sum1 = (sum1 + uint32(byte)) mod 255
    sum2 = (sum2 + sum1) mod 255
  int64((sum2 shl 8) or sum1)
