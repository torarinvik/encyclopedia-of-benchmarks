## Emit the reflected n-bit Gray-code sequence as little-endian u32 values.
proc gray_code*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "gray_code".} =
  if input == nil or inputLength != 1 or input[0] < 0 or input[0] > 13: return -1
  let bitCount = int(input[0])
  let count = if bitCount == 0: 0 else: 1 shl bitCount
  let required = count * 4
  if output == nil or outputCapacity < csize_t(required): return -2
  for index in 0 ..< count:
    let gray = index xor (index shr 1)
    for byte in 0 ..< 4:
      output[4 * index + byte] = uint8((gray shr (8 * byte)) and 255)
  int64(count)
