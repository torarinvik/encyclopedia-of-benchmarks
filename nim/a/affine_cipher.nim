## Transform indexed alphabet symbols with an affine key or its modular inverse.
const MaxInputValues = 612
const MaxTextLength = 512

proc gcdI64(leftValue, rightValue: int64): int64 =
  var left = leftValue
  var right = rightValue
  while right != 0:
    let remainder = left mod right
    left = right
    right = remainder
  left

proc inverseMod(value, modulus: int64): int64 =
  for candidate in 1'i64 ..< modulus:
    if (value * candidate) mod modulus == 1: return candidate
  -1

proc affine_cipher*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64 {.cdecl, exportc: "affine_cipher".} =
  if values == nil or length < 7 or length > MaxInputValues: return -1
  let mode = values[0]
  let keyA = values[1]
  let keyB = values[2]
  let alphabetLengthArg = values[3]
  if mode < 0 or mode > 1 or alphabetLengthArg < 2 or alphabetLengthArg > 95: return -1
  let alphabetLength = int(alphabetLengthArg)
  let textLengthIndex = 4 + alphabetLength
  if int(length) <= textLengthIndex: return -1
  let textLengthArg = values[textLengthIndex]
  if keyA < 0 or keyA > 1_000_000 or keyB < 0 or keyB >= alphabetLengthArg or
      textLengthArg < 0 or textLengthArg > MaxTextLength or
      int(length) != textLengthIndex + 1 + int(textLengthArg) or
      gcdI64(keyA, alphabetLengthArg) != 1: return -1
  let textLength = int(textLengthArg)

  var positions: array[128, int]
  for code in 0 ..< 128: positions[code] = -1
  for index in 0 ..< alphabetLength:
    let symbol = values[4 + index]
    if symbol < 32 or symbol > 126: return -1
    let symbolIndex = int(symbol)
    if positions[symbolIndex] != -1: return -1
    positions[symbolIndex] = index
  for index in 0 ..< textLength:
    let symbol = values[textLengthIndex + 1 + index]
    if symbol < 32 or symbol > 126 or positions[int(symbol)] < 0: return -1
  if textLength > int(outputCapacity): return -2

  let multiplier = keyA mod alphabetLengthArg
  let inverse = if mode == 1: inverseMod(multiplier, alphabetLengthArg) else: 0
  for index in 0 ..< textLength:
    let symbol = values[textLengthIndex + 1 + index]
    let position = int64(positions[int(symbol)])
    let mapped = if mode == 0:
      (position * multiplier + keyB) mod alphabetLengthArg
    else:
      (((position - keyB + alphabetLengthArg) mod alphabetLengthArg) * inverse) mod alphabetLengthArg
    output[index] = uint8(values[4 + int(mapped)])
  int64(textLength)
