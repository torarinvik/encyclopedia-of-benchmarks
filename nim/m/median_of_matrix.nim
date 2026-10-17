const MaxRows = 16
const MaxCells = 128
const MaxInputWords = 1 + MaxRows + MaxCells

type
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]

proc putI32Le(output: U8Output, value: int32) =
  let bits = cast[uint32](value)
  for byte in 0 ..< 4:
    output[byte] = uint8((bits shr (8 * byte)) and 0xFF'u32)

proc median_of_matrix*(input: I64Input, length: csize_t, output: U8Output,
    capacity: csize_t): int64
    {.cdecl, exportc: "median_of_matrix".} =
  if input == nil or length < 1 or length > csize_t(MaxInputWords): return -1
  if input[0] < 0 or input[0] > int64(MaxRows): return -1

  let rowCount = int(input[0])
  let inputLength = int(length)
  var cursor = 1
  var valueCount = 0
  var values: array[MaxCells, int32]
  for _ in 0 ..< rowCount:
    if cursor >= inputLength: return -1
    let rowLength = input[cursor]
    cursor += 1
    if rowLength == -1: continue
    if rowLength < 0 or rowLength > int64(MaxCells): return -1
    let cells = int(rowLength)
    if cells > MaxCells - valueCount or cells > inputLength - cursor: return -1
    for _ in 0 ..< cells:
      let value = input[cursor]
      cursor += 1
      if value < int64(low(int32)) or value > int64(high(int32)): return -1
      values[valueCount] = int32(value)
      valueCount += 1
  if cursor != inputLength or valueCount == 0: return -1

  for index in 1 ..< valueCount:
    let value = values[index]
    var position = index
    while position > 0 and values[position - 1] > value:
      values[position] = values[position - 1]
      position -= 1
    values[position] = value

  if output == nil or capacity < 4: return -2
  var buffer: array[4, uint8]
  putI32Le(cast[U8Output](addr buffer[0]), values[(valueCount - 1) div 2])
  for byte in 0 ..< 4: output[byte] = buffer[byte]
  4
