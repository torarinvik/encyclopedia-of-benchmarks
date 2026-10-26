proc beebs_bit_compress*(values: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "beebs_bit_compress".} =
  if values.isNil or length != 2: return -1
  if values[0] < 0 or values[0] > 4_294_967_295'i64 or
     values[1] < 0 or values[1] > 4_294_967_295'i64: return -1
  var data = uint32(values[0])
  var mask = uint32(values[1])
  var packed = 0'u32
  var outputBit = 1'u32
  while mask != 0:
    if (mask and 1'u32) != 0:
      if (data and 1'u32) != 0: packed = packed or outputBit
      outputBit = outputBit shl 1
    data = data shr 1
    mask = mask shr 1
  int64(packed)
