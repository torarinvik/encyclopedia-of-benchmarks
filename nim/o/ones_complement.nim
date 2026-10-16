const MaxInputLength = 64

proc ones_complement*(input: ptr UncheckedArray[int64], length: csize_t,
                      output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "ones_complement".} =
  if length == 0 or length > MaxInputLength: return -1
  if input.isNil: return -1
  for i in 0 ..< int(length):
    if input[i] != 48 and input[i] != 49: return -1
  if length > capacity or output.isNil: return -2
  for i in 0 ..< int(length):
    output[i] = if input[i] == 48: 49'u8 else: 48'u8
  int64(length)
