## Integer-only Hough accumulator with four fixed quantized normals.
const
  MaxParseableInputLength = 67
  RhoCount = 29
  OutputBytes = 116

type Accumulator = array[OutputBytes, uint8]

proc houghLineTransform*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "hough_line_transform".} =
  if input == nil or length < 3 or length > csize_t(MaxParseableInputLength): return -1
  let heightValue = input[0]
  let widthValue = input[1]
  if heightValue < 1 or heightValue > 8 or widthValue < 1 or widthValue > 8: return -1
  let height = int(heightValue)
  let width = int(widthValue)
  let cells = height * width
  if length != csize_t(2 + cells): return -1
  for index in 0 ..< cells:
    if input[index + 2] != 0 and input[index + 2] != 1: return -1
  if output == nil or outputCapacity < csize_t(OutputBytes): return -2

  var accumulator: Accumulator
  for index in 0 ..< OutputBytes: accumulator[index] = 0
  for row in 0 ..< height:
    for column in 0 ..< width:
      if input[2 + row * width + column] == 0: continue
      let x = int64(column)
      let y = int64(row)
      let rho = [x, x + y, y, -x + y]
      for angle in 0 ..< 4:
        let bin = angle * RhoCount + int(rho[angle] + 14)
        inc accumulator[bin]
  for index in 0 ..< OutputBytes: output[index] = accumulator[index]
  int64(OutputBytes)
