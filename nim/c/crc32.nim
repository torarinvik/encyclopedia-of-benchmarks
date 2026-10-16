const MaxLength = 100001
const Polynomial = 3988292384'i64
const Initial = 4294967295'i64
proc crc32*(values: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl,exportc:"crc32".} =
  if length > csize_t(MaxLength) or (length != 0 and values == nil): return -1
  var crc = Initial
  for i in 0 ..< int(length):
    let value = values[i]
    if value < 0 or value > 255: return -1
    crc = crc xor value
    for bit in 0 ..< 8:
      if (crc and 1) != 0: crc = (crc shr 1) xor Polynomial
      else: crc = crc shr 1
  crc xor Initial
