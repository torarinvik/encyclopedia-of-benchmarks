proc storeI64Le(value: int64, output: ptr UncheckedArray[uint8], offset: int) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255)

proc alternative_list_arrange*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "alternative_list_arrange".} =
  if input.isNil or length < 2: return -1
  if input[0] < 0 or input[0] > 64: return -1
  let a = int(input[0])
  if csize_t(1 + a) >= length or input[1 + a] < 0 or input[1 + a] > 64: return -1
  let b = int(input[1 + a])
  if length != csize_t(2 + a + b): return -1
  let count = a + b
  if count == 0: return 0
  let requiredBytes = csize_t(count * 8)
  if output.isNil or outputCapacity < requiredBytes: return -2
  var written = 0
  for i in 0 ..< max(a, b):
    if i < a:
      storeI64Le(input[1 + i], output, written * 8)
      inc written
    if i < b:
      storeI64Le(input[2 + a + i], output, written * 8)
      inc written
  int64(count)
