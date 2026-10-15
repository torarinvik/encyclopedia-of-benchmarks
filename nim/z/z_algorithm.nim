type
  I64Input = ptr UncheckedArray[int64]
  ByteOutput = ptr UncheckedArray[uint8]

proc z_algorithm*(input: I64Input, length: csize_t, output: ByteOutput,
                  outputCapacity: csize_t): int64
    {.cdecl, exportc: "z_algorithm".} =
  if input.isNil or length < 1 or length > 2048: return -1
  if input[0] < 0 or input[0] > 2047: return -1
  let count = int(input[0])
  if length != csize_t(count + 1): return -1
  let outputBytes = count * 4
  if outputCapacity < csize_t(outputBytes) or (count > 0 and output.isNil): return -2

  var z: array[2047, int]
  var left = 0
  var right = 0
  for index in 1 ..< count:
    if index < right:
      z[index] = min(z[index - left], right - index)
    while index + z[index] < count and input[1 + z[index]] == input[1 + index + z[index]]:
      inc z[index]
    if index + z[index] > right:
      left = index
      right = index + z[index]
  for index in 0 ..< count:
    let value = uint32(z[index])
    for byte in 0 ..< 4:
      output[index * 4 + byte] = uint8((value shr (byte * 8)) and 255)
  int64(count)
