type I64Array = ptr UncheckedArray[int64]
type ByteArray = ptr UncheckedArray[uint8]

proc putI32Le(output: ByteArray, offset: int, value: int32) =
  let bits = cast[uint32](value)
  for byte in 0 ..< 4: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc dilation_operation*(input: I64Array, length: csize_t, output: ByteArray, outputCapacity: csize_t): int64
    {.cdecl, exportc: "dilation_operation".} =
  if input.isNil or length < 12 or length > 267: return -1
  let rowsValue = input[0]
  let columnsValue = input[1]
  if rowsValue < 1 or rowsValue > 16 or columnsValue < 1 or columnsValue > 16: return -1
  let rows = int(rowsValue)
  let columns = int(columnsValue)
  let cells = rows * columns
  if length != csize_t(2 + cells + 9): return -1
  for i in 0 ..< cells + 9:
    if input[2 + i] < 0 or input[2 + i] > 1: return -1
  if output.isNil or outputCapacity < csize_t(cells * 4): return -2
  for y in 0 ..< rows:
    for x in 0 ..< columns:
      var sum = 0
      for ky in 0 ..< 3:
        for kx in 0 ..< 3:
          let imageY = y + ky - 1
          let imageX = x + kx - 1
          if imageY >= 0 and imageY < rows and imageX >= 0 and imageX < columns:
            sum += int(input[2 + imageY * columns + imageX] * input[2 + cells + ky * 3 + kx])
      putI32Le(output, (y * columns + x) * 4, int32(if sum > 0: 1 else: 0))
  int64(cells)
