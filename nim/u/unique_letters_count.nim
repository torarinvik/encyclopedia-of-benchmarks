const MaxTextLength = 256
const MaxInputLength = MaxTextLength + 1
const LetterCount = 26
const BytesPerRecord = 8

proc storeI32Le(output: ptr UncheckedArray[uint8], position: int, value: int64) =
  let bits = cast[uint32](int32(value))
  for byte in 0 ..< 4:
    output[position + byte] = uint8((bits shr (byte * 8)) and 255'u32)

proc unique_letters_count*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "unique_letters_count".} =
  if input == nil or length < 1 or length > csize_t(MaxInputLength): return -1
  let textLengthValue = input[0]
  if textLengthValue < 0 or textLengthValue > MaxTextLength or length != csize_t(textLengthValue + 1): return -1
  let textLength = int(textLengthValue)

  for index in 0 ..< textLength:
    if input[index + 1] < 0 or input[index + 1] > 127: return -1

  var frequencies: array[LetterCount, int32] = default(array[LetterCount, int32])
  var firstSeen: array[LetterCount, int32] = default(array[LetterCount, int32])
  var uniqueCount = 0
  for index in 0 ..< textLength:
    var byte = input[index + 1]
    if byte >= 65 and byte <= 90:
      byte += 32
    elif byte < 97 or byte > 122:
      continue
    let letterIndex = int(byte - 97)
    if frequencies[letterIndex] == 0:
      firstSeen[uniqueCount] = int32(byte)
      inc uniqueCount
    inc frequencies[letterIndex]

  let maximumResult = min(textLength, LetterCount)
  let requiredCapacity = csize_t(maximumResult * BytesPerRecord)
  if outputCapacity < requiredCapacity or (requiredCapacity > 0 and output == nil): return -2

  for index in 0 ..< uniqueCount:
    let letter = firstSeen[index]
    storeI32Le(output, index * BytesPerRecord, int64(letter))
    storeI32Le(output, index * BytesPerRecord + 4, int64(frequencies[int(letter - 97)]))
  int64(uniqueCount)
