proc storeI64Le(value: int64, output: ptr UncheckedArray[uint8], offset: int) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc matrix_multiplication*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "matrix_multiplication".} =
  if input.isNil or length < 1: return -2
  let dimension = input[0]
  if dimension < 2 or dimension > 8: return -2
  let n = int(dimension)
  let cells = n * n
  if int(length) != 1 + 2 * cells: return -2
  for index in 0 ..< 2 * cells:
    if input[1 + index] < -1000 or input[1 + index] > 1000: return -2
  if output.isNil or outputCapacity < csize_t(cells * 8): return -3

  for row in 0 ..< n:
    for column in 0 ..< n:
      var sum = 0'i64
      for index in 0 ..< n:
        sum += input[1 + row * n + index] * input[1 + cells + index * n + column]
      storeI64Le(sum, output, (row * n + column) * 8)
  int64(cells)
