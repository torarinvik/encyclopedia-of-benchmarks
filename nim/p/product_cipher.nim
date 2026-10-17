const
  MaxInputValues = 259
  MaxTextLength = 256
  MaxColumns = 64
  MaxOutputBytes = 315

type
  I64Array = ptr UncheckedArray[int64]
  ByteArray = ptr UncheckedArray[uint8]
  PaddedArray = array[MaxOutputBytes, uint8]

proc product_cipher*(input: I64Array, length: csize_t, output: ByteArray,
    outputCapacity: csize_t): int64 {.cdecl, exportc: "product_cipher".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputValues): return -1
  let columnsValue = input[0]
  let textLengthValue = input[1]
  if columnsValue < 1 or columnsValue > MaxColumns or
      textLengthValue < 0 or textLengthValue > MaxTextLength: return -1
  let columns = int(columnsValue)
  let textLength = int(textLengthValue)
  if length != csize_t(2 + textLength): return -1
  for index in 0 ..< textLength:
    let byte = input[2 + index]
    if byte < 0 or byte > 127 or byte == 10 or byte == 13: return -1

  let paddedLength = if textLength == 0: 0 else: ((textLength + columns - 1) div columns) * columns
  if paddedLength > MaxOutputBytes: return -1
  if paddedLength == 0: return 0
  if output.isNil or outputCapacity < csize_t(paddedLength): return -2

  var padded: PaddedArray
  for index in 0 ..< textLength:
    padded[index] = uint8(input[2 + index] + 5)
  for index in textLength ..< paddedLength:
    padded[index] = uint8(ord('/'))
  let rows = paddedLength div columns
  var written = 0
  for column in 0 ..< columns:
    for row in 0 ..< rows:
      output[written] = padded[column + row * columns]
      inc written
  int64(written)
