proc writeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255)

proc stream_vector_kernels*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "stream_vector_kernels".} =
  if input.isNil or length < 2 or length > 259: return -1
  let mode = input[0]
  let countValue = input[1]
  if mode < 0 or mode > 3 or countValue < 0 or countValue > 128: return -1
  let count = int(countValue)
  let hasAlpha = mode == 1 or mode == 3
  let arrayCount = if mode == 0 or mode == 1: 1 else: 2
  let expectedLength = 2 + (if hasAlpha: 1 else: 0) + arrayCount * count
  if int(length) != expectedLength: return -1

  var aStart = 2
  var alpha = 0'i64
  if hasAlpha:
    alpha = input[2]
    if alpha < -1000 or alpha > 1000: return -1
    aStart = 3
  let bStart = aStart + count
  for index in 0 ..< arrayCount * count:
    let value = input[aStart + index]
    if value < -1000 or value > 1000: return -1

  var staged: array[128, int64]
  for index in 0 ..< count:
    let a = input[aStart + index]
    var value: int64
    case mode
    of 0: value = a
    of 1: value = alpha * a
    of 2: value = a + input[bStart + index]
    else: value = a + alpha * input[bStart + index]
    staged[index] = value

  let outputBytes = count * 8
  if output.isNil or int(capacity) < outputBytes: return -2
  for index in 0 ..< count:
    writeI64Le(output, index * 8, staged[index])
  int64(outputBytes)
