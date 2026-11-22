const
  MaxStringLength = 256
  MaxParseableInputLength = 259

proc string_left_rotation*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, dynlib, exportc: "string_left_rotation".} =
  if input.isNil or length < 2 or length > csize_t(MaxParseableInputLength): return -1
  let rawLength = input[0]
  let rawRotation = input[1]
  if rawLength < 0 or rawLength > MaxStringLength or rawRotation < 0 or rawRotation > rawLength: return -1
  let textLength = int(rawLength)
  if int(length) != textLength + 2: return -1
  if textLength == 0: return 0
  var units: array[MaxStringLength, uint16]
  var observedBits: uint64
  for i in 0 ..< textLength:
    let value = cast[uint64](input[i + 2])
    observedBits = observedBits or value
    units[i] = cast[uint16](value)
  if observedBits > 65535: return -1
  let required = textLength * 2
  if output.isNil or capacity < csize_t(required): return -2
  let rotation = int(rawRotation)
  for source in rotation ..< textLength:
    let destination = 2 * (source - rotation)
    let value = units[source]
    output[destination] = uint8(value and 0xff'u16)
    output[destination + 1] = uint8(value shr 8)
  let suffixBytes = 2 * (textLength - rotation)
  for source in 0 ..< rotation:
    let destination = suffixBytes + 2 * source
    let value = units[source]
    output[destination] = uint8(value and 0xff'u16)
    output[destination + 1] = uint8(value shr 8)
  int64(required)
