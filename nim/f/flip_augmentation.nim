## Flip grayscale pixels and reflect normalized bounding-box centers.
const MaxInputLength = 340
const CoordinateScale = 1_000_000'i64

proc storeI32Le(output: ptr UncheckedArray[uint8], position: int, value: int32) =
  let bits = cast[uint32](value)
  for byte in 0 ..< 4:
    output[position + byte] = uint8((bits shr (byte * 8)) and 255'u32)

proc flip_augmentation*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "flip_augmentation".} =
  if values == nil or length < 4 or length > csize_t(MaxInputLength): return -1
  if values[0] < 1 or values[0] > 16 or values[1] < 1 or values[1] > 16: return -1
  if (values[2] != 0 and values[2] != 1) or values[3] < 0 or values[3] > 16: return -1
  let width = int(values[0])
  let height = int(values[1])
  let flipType = int(values[2])
  let boxCount = int(values[3])
  let pixelCount = width * height
  if int(length) != 4 + pixelCount + 5 * boxCount: return -1
  for index in 0 ..< pixelCount:
    if values[4 + index] < 0 or values[4 + index] > 255: return -1
  for box in 0 ..< boxCount:
    let base = 4 + pixelCount + 5 * box
    if values[base] < 0 or values[base] > int64(high(int32)): return -1
    for field in 1 ..< 5:
      if values[base + field] < 0 or values[base + field] > CoordinateScale: return -1
  let outputBytes = pixelCount + 20 * boxCount
  if output == nil or outputCapacity < csize_t(outputBytes): return -2

  for row in 0 ..< height:
    for column in 0 ..< width:
      let sourceRow = if flipType == 0: height - 1 - row else: row
      let sourceColumn = if flipType == 1: width - 1 - column else: column
      output[row * width + column] = uint8(values[4 + sourceRow * width + sourceColumn])
  for box in 0 ..< boxCount:
    let base = 4 + pixelCount + 5 * box
    let outputBase = pixelCount + 20 * box
    for field in 0 ..< 5:
      var value = values[base + field]
      if flipType == 1 and field == 1: value = CoordinateScale - value
      if flipType == 0 and field == 2: value = CoordinateScale - value
      storeI32Le(output, outputBase + 4 * field, int32(value))
  int64(outputBytes)
