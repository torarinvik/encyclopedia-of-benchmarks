type I64Input = ptr UncheckedArray[int64]
type ByteOutput = ptr UncheckedArray[uint8]

const MaxInputLength = 27

proc writeF64Le(output: ByteOutput, offset: int, value: float64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 0xFF'u64)

proc gramMatrix(values: I64Input, channels, pixels, part: int64,
                matrix: var array[9, float64]) =
  let featureCount = channels * pixels
  for row in 0 ..< int(channels):
    for column in 0 ..< int(channels):
      var dot = 0.0
      for pixel in 0 ..< int(pixels):
        let rowValue = float64(values[3 + int(part * featureCount) + row * int(pixels) + pixel]) / 1000.0
        let columnValue = float64(values[3 + int(part * featureCount) + column * int(pixels) + pixel]) / 1000.0
        dot += rowValue * columnValue
      matrix[row * int(channels) + column] = dot / float64(featureCount)

proc gramian*(values: I64Input, length: csize_t, output: ByteOutput,
              outputCapacity: csize_t): int64 {.cdecl, exportc: "gramian".} =
  if values == nil or length < 3 or length > MaxInputLength: return -1
  let operation = values[0]
  let channels = values[1]
  let pixels = values[2]
  if (operation != 0 and operation != 1) or channels < 1 or channels > 3 or
      pixels < 1 or pixels > 4: return -1
  let featureCount = channels * pixels
  let mapCount = if operation == 1: 2 else: 1
  if length != csize_t(3 + featureCount * mapCount): return -1
  for index in 3 ..< int(length):
    if values[index] < -1000 or values[index] > 1000: return -1

  let outputCount = if operation == 1: 1 else: int(channels * channels)
  let requiredBytes = outputCount * 8
  if output == nil or outputCapacity < csize_t(requiredBytes): return -2

  var first: array[9, float64]
  gramMatrix(values, channels, pixels, 0, first)
  if operation == 0:
    for index in 0 ..< outputCount:
      writeF64Le(output, index * 8, first[index])
  else:
    var second: array[9, float64]
    gramMatrix(values, channels, pixels, 1, second)
    var loss = 0.0
    for index in 0 ..< int(channels * channels):
      let difference = first[index] - second[index]
      loss += difference * difference
    writeF64Le(output, 0, loss)
  int64(requiredBytes)
