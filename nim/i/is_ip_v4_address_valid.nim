const MaxInputLength = 32

proc is_ip_v4_address_valid*(bytes: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "is_ip_v4_address_valid".} =
  if (bytes == nil and length != 0) or length > csize_t(MaxInputLength): return -1
  for index in 0 ..< int(length):
    if bytes[index] < 0 or bytes[index] > 127: return -1
  var segmentCount = 0
  var digitCount = 0
  var octet = 0'i64
  var leadingZero = false
  for index in 0 ..< int(length):
    let value = bytes[index]
    if value == 46:
      if digitCount == 0 or octet > 255 or segmentCount >= 3: return 0
      inc segmentCount
      digitCount = 0
      octet = 0
      leadingZero = false
    else:
      if value < 48 or value > 57: return 0
      if digitCount == 0: leadingZero = value == 48
      elif leadingZero: return 0
      octet = octet * 10 + value - 48
      if octet > 255: return 0
      inc digitCount
      if digitCount > 3: return 0
  if segmentCount == 3 and digitCount > 0 and octet <= 255: 1 else: 0
