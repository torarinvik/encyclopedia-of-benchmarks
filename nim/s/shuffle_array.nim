const
  MaxN = 32
  MaxParseableInputLength = 67
  MaxOutputBytes = 520
  I32Min = -2_147_483_648'i64
  I32Max = 2_147_483_647'i64

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255'u64)

proc shuffle_array*(input: ptr UncheckedArray[int64], inputLength: csize_t,
                    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "shuffle_array".} =
  if input == nil or inputLength < 2 or inputLength > csize_t(MaxParseableInputLength): return -1
  let variant = input[0]
  let nValue = input[1]
  if (variant != 0 and variant != 1) or nValue < 0 or nValue > MaxN: return -1
  let n = int(nValue)
  let valueCount = if variant == 0: n else: 2 * n
  let drawCount = if variant == 0 and n > 0: n - 1 else: 0
  if int(inputLength) != 2 + valueCount + drawCount: return -1

  var resultValues: array[2 * MaxN, int64]
  let resultCount = valueCount
  for index in 0 ..< valueCount:
    let value = input[2 + index]
    if value < I32Min or value > I32Max: return -1
    resultValues[index] = value

  if variant == 0:
    for drawIndex in 0 ..< drawCount:
      let currentIndex = n - 1 - drawIndex
      let chosenValue = input[2 + n + drawIndex]
      if chosenValue < 0 or chosenValue > int64(currentIndex): return -1
      let chosenIndex = int(chosenValue)
      swap(resultValues[currentIndex], resultValues[chosenIndex])
  else:
    for index in 0 ..< n:
      resultValues[2 * index] = input[2 + index]
      resultValues[2 * index + 1] = input[2 + n + index]

  let outputBytes = 8 * (resultCount + 1)
  if outputBytes > MaxOutputBytes or output == nil or outputCapacity < csize_t(outputBytes): return -2
  storeI64Le(output, 0, int64(resultCount))
  for index in 0 ..< resultCount:
    storeI64Le(output, 8 * (index + 1), resultValues[index])
  int64(outputBytes)
