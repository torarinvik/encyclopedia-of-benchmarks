proc hash_xor8*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "hash_xor8".} =
  if length > 100001 or (values == nil and length != 0): return -1
  for i in 0 ..< int(length):
    if values[i] == 0: break
    if values[i] < 0 or values[i] > 127: return -1
  var hash = 0'u32
  for i in 0 ..< int(length):
    if values[i] == 0: break
    hash = (hash + uint32(values[i])) and 0xff'u32
  int64(((hash xor 0xff'u32) + 1'u32) and 0xff'u32)
