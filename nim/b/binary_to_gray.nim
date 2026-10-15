## Convert an ASCII binary string to equal-width ASCII Gray code.
proc binary_to_gray*(bits: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "binary_to_gray".} =
  if bits == nil or length < 1 or length > 66: return -1
  for index in 0'u64 ..< uint64(length):
    if bits[csize_t(index)] != 48 and bits[csize_t(index)] != 49: return -1
  if output == nil or outputCapacity < length: return -2
  for index in 0'u64 ..< uint64(length):
    let current = bits[csize_t(index)] - 48
    let previous = if index == 0: 0'i64 else: bits[csize_t(index - 1)] - 48
    output[csize_t(index)] = uint8(48 + (current xor previous))
  int64(length)
