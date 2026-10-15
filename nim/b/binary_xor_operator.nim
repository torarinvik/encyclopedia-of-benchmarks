proc binary_xor_operator*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "binary_xor_operator".} =
  if input == nil or length != 2: return -1
  let aValue = input[0]
  let bValue = input[1]
  if aValue < 0 or aValue > 2147483647 or bValue < 0 or bValue > 2147483647: return -1
  let a = uint64(aValue)
  let b = uint64(bValue)
  var largest = max(a, b)
  var width = 1
  while largest > 1:
    largest = largest shr 1
    inc width
  let outputLength = width + 2
  if capacity < csize_t(outputLength) or output == nil: return -2
  output[0] = uint8(ord('0'))
  output[1] = uint8(ord('b'))
  let result = a xor b
  for i in 0 ..< width:
    let bit = width - 1 - i
    output[2 + i] = if ((result shr bit) and 1) == 1: uint8(ord('1')) else: uint8(ord('0'))
  int64(outputLength)
