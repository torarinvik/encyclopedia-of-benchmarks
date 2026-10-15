## Encode the C# uint overload as exactly 32 ASCII binary digits.
proc int2_binary*(value: int64, output: ptr UncheckedArray[uint8],
    output_capacity: csize_t): int64 {.cdecl, exportc: "int2_binary".} =
  if value < 0 or value > 4_294_967_295'i64: return -1
  if output == nil or output_capacity < 32: return -2

  var remaining = uint32(value)
  var mostSignificantBit = 0x8000_0000'u32
  for i in 0 ..< 32:
    if remaining >= mostSignificantBit:
      output[i] = uint8(ord('1'))
      remaining -= mostSignificantBit
    else:
      output[i] = uint8(ord('0'))
    mostSignificantBit = mostSignificantBit div 2
  return 32
