const MaxArrayLength = 64
const MaxInputLength = 2 * (MaxArrayLength + 1)
const BytesPerValue = 4

proc storeI32Le(output: ptr UncheckedArray[uint8], position: int, value: int64) =
  let bits = cast[uint32](int32(value))
  for byte in 0 ..< BytesPerValue:
    output[position + byte] = uint8((bits shr (byte * 8)) and 255'u32)

proc union_of_two_arrays*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "union_of_two_arrays".} =
  if input == nil or length < 2 or length > csize_t(MaxInputLength): return -1
  let firstLengthValue = input[0]
  if firstLengthValue < 0 or firstLengthValue > MaxArrayLength: return -1
  let firstLength = int(firstLengthValue)
  let secondLengthPosition = 1 + firstLength
  if secondLengthPosition >= int(length): return -1
  let secondLengthValue = input[secondLengthPosition]
  if secondLengthValue < 0 or secondLengthValue > MaxArrayLength: return -1
  let secondLength = int(secondLengthValue)
  let secondStart = secondLengthPosition + 1
  if secondStart + secondLength != int(length): return -1

  for index in 0 ..< firstLength:
    let value = input[1 + index]
    if value < int64(low(int32)) or value > int64(high(int32)): return -1
    if index > 0 and input[index] > value: return -1
  for index in 0 ..< secondLength:
    let value = input[secondStart + index]
    if value < int64(low(int32)) or value > int64(high(int32)): return -1
    if index > 0 and input[secondStart + index - 1] > value: return -1

  let maximumResult = firstLength + secondLength
  if outputCapacity < csize_t(maximumResult * BytesPerValue) or (maximumResult > 0 and output == nil): return -2
  var firstIndex = 0
  var secondIndex = 0
  var resultCount = 0
  var previousValue = 0'i64
  while firstIndex < firstLength or secondIndex < secondLength:
    var value: int64
    if firstIndex == firstLength:
      value = input[secondStart + secondIndex]
      inc secondIndex
    elif secondIndex == secondLength:
      value = input[1 + firstIndex]
      inc firstIndex
    else:
      let first = input[1 + firstIndex]
      let second = input[secondStart + secondIndex]
      if first < second:
        value = first
        inc firstIndex
      elif first > second:
        value = second
        inc secondIndex
      else:
        value = first
        inc firstIndex
        inc secondIndex
    if resultCount == 0 or value != previousValue:
      storeI32Le(output, resultCount * BytesPerValue, value)
      previousValue = value
      inc resultCount
  int64(resultCount)
