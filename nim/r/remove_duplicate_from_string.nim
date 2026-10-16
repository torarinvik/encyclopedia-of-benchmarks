const
  MaxTextLength = 512
  MaxInputLength = MaxTextLength + 2

proc remove_duplicate_from_string*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "remove_duplicate_from_string".} =
  if input == nil or length < 1 or length > csize_t(MaxInputLength): return -1
  let textLengthValue = input[0]
  if textLengthValue < 0 or textLengthValue > MaxTextLength: return -1
  let textLength = int(textLengthValue)
  if length != csize_t(1 + textLength): return -1

  var result: array[MaxTextLength, uint8]
  var seen: array[128, bool] = default(array[128, bool])
  var resultLength = 0
  for index in 0 ..< textLength:
    let value = input[index + 1]
    if value < 0 or value > 127: return -1
    let byte = int(value)
    if not seen[byte]:
      seen[byte] = true
      result[resultLength] = uint8(value)
      inc resultLength

  if outputCapacity < csize_t(resultLength) or (resultLength != 0 and output == nil): return -2
  for index in 0 ..< resultLength: output[index] = result[index]
  int64(resultLength)
