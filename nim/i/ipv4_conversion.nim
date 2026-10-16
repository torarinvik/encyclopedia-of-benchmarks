const InvalidResult = low(int64)

proc ipv4_conversion*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "ipv4_conversion".} =
  if input.isNil or length != 4: return InvalidResult
  var address: int64 = 0
  for index in 0 ..< 4:
    let octet = input[index]
    if octet < 0 or octet > 255: return InvalidResult
    address = address * 256 + octet
  address
