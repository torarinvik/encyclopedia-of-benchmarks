const MaxLength = 64
const BytesPerValue = 4

proc storeI32Le(output: ptr UncheckedArray[uint8], position: int, value: int64) =
  let bits = cast[uint32](int32(value))
  for byte in 0 ..< BytesPerValue:
    output[position + byte] = uint8((bits shr (byte * 8)) and 255'u32)

proc compress*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "compress".} =
  if input == nil or length < 1 or length > csize_t(MaxLength + 1): return -1
  let countValue = input[0]
  if countValue < 0 or countValue > MaxLength or length != 1 + csize_t(countValue): return -1
  let count = int(countValue)
  for index in 0 ..< count:
    let value = input[1 + index]
    if value < int64(low(int32)) or value > int64(high(int32)): return -1

  let maximumBytes = csize_t(count * BytesPerValue)
  if outputCapacity < maximumBytes or (maximumBytes > 0 and output == nil): return -2
  var resultCount = 0
  var previous = 0'i64
  for index in 0 ..< count:
    let value = input[1 + index]
    if index == 0 or value != previous:
      storeI32Le(output, resultCount * BytesPerValue, value)
      inc resultCount
    previous = value
  int64(resultCount)
