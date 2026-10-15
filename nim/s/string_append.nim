## Append two bounded printable ASCII strings.

proc string_append*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "string_append".} =
  if input == nil or length < 2 or input[0] < 0 or input[0] > 64: return -1
  let firstLength = int(input[0])
  if csize_t(1 + firstLength) >= length or input[1 + firstLength] < 0 or input[1 + firstLength] > 64: return -1
  let secondLength = int(input[1 + firstLength])
  if length != csize_t(2 + firstLength + secondLength): return -1
  for i in 0 ..< firstLength:
    if input[2 + i] < 32 or input[2 + i] > 126: return -1
  for i in 0 ..< secondLength:
    if input[2 + firstLength + i] < 32 or input[2 + firstLength + i] > 126: return -1
  let count = firstLength + secondLength
  if outputCapacity < csize_t(count) or (count != 0 and output == nil): return -2
  for i in 0 ..< firstLength: output[i] = uint8(input[2 + i])
  for i in 0 ..< secondLength: output[firstLength + i] = uint8(input[2 + firstLength + i])
  int64(count)
