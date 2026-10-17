const MaxBytes = 256
const MaxInputValues = MaxBytes + 3

proc writeI64Le(output: ptr UncheckedArray[uint8], position: int, value: int64) =
  var bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[position + byte] = uint8((bits shr (8 * byte)) and 0xff)

proc tbc_padding*(input: ptr UncheckedArray[int64], length: csize_t,
                  output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "tbc_padding".} =
  if input.isNil or length < 3 or length > csize_t(MaxInputValues): return -1
  let operation = input[0]
  let offsetValue = input[1]
  let countValue = input[2]
  if operation < 0 or operation > 2 or countValue < 0 or countValue > MaxBytes or
      int64(length) != countValue + 3: return -1
  let count = int(countValue)
  if (operation == 0 and (count == 0 or offsetValue < 0 or offsetValue > countValue)) or
      (operation != 0 and offsetValue != 0) or (operation == 2 and count == 0): return -1
  for index in 0 ..< count:
    if input[index + 3] < 0 or input[index + 3] > 255: return -1

  if operation == 0:
    let offset = int(offsetValue)
    var previous = input[count + 2]
    if offset > 0: previous = input[offset + 2]
    let code = if (previous and 1) == 0: 0xff'u8 else: 0'u8
    let needed = 8 + count
    if output.isNil or int(capacity) < needed: return -2
    writeI64Le(output, 0, int64(count - offset))
    for index in 0 ..< count:
      output[8 + index] = if index >= offset: code else: uint8(input[3 + index])
    return int64(needed)

  if operation == 1:
    var survivors = count
    var code: int64 = 0
    if count > 0:
      code = if (input[2 + count] and 1) == 0: 0 else: 255
      while survivors > 0 and input[2 + survivors] == code: dec survivors
    if output.isNil or int(capacity) < survivors: return -2
    for index in 0 ..< survivors: output[index] = uint8(input[3 + index])
    return int64(survivors)

  let terminal = input[2 + count]
  if terminal != 0 and terminal != 255: return -1
  var paddingCount = 0
  while paddingCount < count and input[2 + count - paddingCount] == terminal: inc paddingCount
  if output.isNil or capacity < 8: return -2
  writeI64Le(output, 0, int64(paddingCount))
  8
