## Portable byte-channel brightness and contrast transforms.
proc truncateDivide(numerator, denominator: int64): int64 =
  if numerator < 0: -((-numerator) div denominator) else: numerator div denominator

proc transformChannel(channel, level, mode: int64): int64 =
  var value: int64
  if mode == 0:
    value = channel + level
  else:
    let denominator = 255'i64 * (259 - level)
    let numerator = 128'i64 * denominator + 259'i64 * (level + 255) * (channel - 128)
    value = truncateDivide(numerator, denominator)
  if value < 0: return 0
  if value > 255: return 255
  value

proc imagePointTransform(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t, mode: int64): int64 =
  if values == nil or length < 1 or length > csize_t(4096): return -1
  let level = values[0]
  if level < -255 or level > 255: return -1
  let channels = int(length - 1)
  for index in 0 ..< channels:
    if values[index + 1] < 0 or values[index + 1] > 255: return -1
  if csize_t(channels) > outputCapacity or (channels != 0 and output == nil): return -2
  for index in 0 ..< channels:
    output[index] = uint8(transformChannel(values[index + 1], level, mode))
  int64(channels)

proc change_brightness*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "change_brightness".} =
  imagePointTransform(values, length, output, outputCapacity, 0)

proc change_contrast*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "change_contrast".} =
  imagePointTransform(values, length, output, outputCapacity, 1)
