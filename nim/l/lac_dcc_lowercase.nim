const MaxCharacters = 31
const MaxOutputBytes = 1 + 2 * MaxCharacters

proc misc_lowercase*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "misc_lowercase".} =
  if input.isNil or inputLength < csize_t(1) or inputLength > csize_t(MaxCharacters + 2): return -1
  let rawLength = input[0]
  if rawLength < 0 or rawLength > int64(MaxCharacters) or inputLength != csize_t(rawLength + 1): return -1
  let length = int(rawLength)
  var lowered: array[MaxCharacters, uint16]
  var asciiFlag = 1'u8
  for index in 0 ..< length:
    let raw = input[index + 1]
    if raw < 0 or raw > 65535: return -1
    let value = uint16(raw)
    if value > 0x7f'u16: asciiFlag = 0'u8
    lowered[index] = value + (if value >= uint16(ord('A')) and value <= uint16(ord('Z')): 32'u16 else: 0'u16)
  let required = 1 + 2 * length
  if output.isNil or outputCapacity < csize_t(required): return -2
  var staged: array[MaxOutputBytes, uint8]
  staged[0] = asciiFlag
  for index in 0 ..< length:
    staged[1 + 2 * index] = uint8(lowered[index] and 0xff'u16)
    staged[2 + 2 * index] = uint8(lowered[index] shr 8)
  for index in 0 ..< required: output[index] = staged[index]
  int64(required)
