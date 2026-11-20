proc nmea_xor_checksum*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "nmea_xor_checksum".} =
  if values.isNil or length == 0 or length > 78: return -1
  let payloadLength = values[0]
  if payloadLength < 0 or payloadLength > 76 or
      length != csize_t(payloadLength + 1): return -1
  for i in 1 ..< int(length):
    let byte = values[i]
    if byte < 0 or byte > 127: return -1
    result = result xor byte
