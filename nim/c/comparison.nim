const MaxStringLength = 64
const MaxInputLength = 3 + 2 * MaxStringLength

proc foldAscii(value, mode: int64): int64 =
  if mode == 1 and value >= 65 and value <= 90: value + 32 else: value

proc comparison*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "comparison".} =
  if values == nil or length < 3 or length > csize_t(MaxInputLength): return -2
  let mode = values[0]
  let firstLengthValue = values[1]
  if (mode != 0 and mode != 1) or firstLengthValue < 0 or firstLengthValue > MaxStringLength: return -2
  let firstLength = int(firstLengthValue)
  let secondLengthPosition = 2 + firstLength
  if secondLengthPosition >= int(length): return -2
  let secondLengthValue = values[secondLengthPosition]
  if secondLengthValue < 0 or secondLengthValue > MaxStringLength: return -2
  let secondLength = int(secondLengthValue)
  let secondStart = secondLengthPosition + 1
  if secondStart + secondLength != int(length): return -2

  for index in 0 ..< firstLength:
    if values[2 + index] < 1 or values[2 + index] > 127: return -2
  for index in 0 ..< secondLength:
    if values[secondStart + index] < 1 or values[secondStart + index] > 127: return -2

  let commonLength = min(firstLength, secondLength)
  for index in 0 ..< commonLength:
    let left = foldAscii(values[2 + index], mode)
    let right = foldAscii(values[secondStart + index], mode)
    if left < right: return -1
    if left > right: return 1
  if firstLength < secondLength: return -1
  if firstLength > secondLength: return 1
  0
