import std/bitops

proc count_leading_zeros*(value: int64): int64 {.cdecl, exportc: "count_leading_zeros".} =
  if value < low(int32).int64 or value > high(int32).int64:
    return -1
  if value == 0:
    return 32
  countLeadingZeroBits(cast[uint32](int32(value))).int64
