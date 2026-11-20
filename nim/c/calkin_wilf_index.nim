## Uncompiled indexed Calkin–Wilf fraction draft.
proc calkin_wilf_index*(input: ptr UncheckedArray[int64], length: csize_t,
                        output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "calkin_wilf_index".} =
  if input == nil or length != 1: return -1
  let raw = input[0]
  if raw < 1 or raw >= (1'i64 shl 62): return -1
  if output == nil or capacity < 16: return -2
  let index = uint64(raw)
  var high = 1'u64
  while high <= index div 2: high *= 2
  var numerator = 1'u64
  var denominator = 1'u64
  high = high div 2
  while high != 0:
    if (index and high) != 0: numerator += denominator
    else: denominator += numerator
    high = high div 2
  for i in 0 ..< 8:
    output[i] = uint8((numerator shr (8*i)) and 255)
    output[i+8] = uint8((denominator shr (8*i)) and 255)
  16
