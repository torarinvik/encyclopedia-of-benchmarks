## Convert most-significant-first binary digits to a signed 64-bit decimal value.
proc binary_to_decimal*(bits: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "binary_to_decimal".} =
  if length == 0 or length > 63:
    return -1
  var value = 0'u64
  for index in 0 ..< int(length):
    if bits[index] != 0 and bits[index] != 1:
      return -1
    value = value * 2 + uint64(bits[index])
  int64(value)
