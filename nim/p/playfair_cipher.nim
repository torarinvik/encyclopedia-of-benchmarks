const
  MinParseableInputLength = 3
  MaxParseableInputLength = 157
  MaxKeyLength = 25
  MaxTextLength = 128
  FnvOffsetBasis = 14695981039346656037'u64
  FnvPrime = 1099511628211'u64
  Low63Mask = 0x7fffffffffffffff'u64
  Alphabet = "ABCDEFGHIKLMNOPQRSTUVWXYZ"

proc playfair_cipher*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "playfair_cipher".} =
  if input.isNil or length < csize_t(MinParseableInputLength) or
      length > csize_t(MaxParseableInputLength):
    return -1

  let operation = input[0]
  let keyLengthValue = input[1]
  if operation < 0 or operation > 1 or keyLengthValue < 0 or keyLengthValue > int64(MaxKeyLength):
    return -1
  let keyLength = int(keyLengthValue)
  let textLengthIndex = 2 + keyLength
  if length <= csize_t(textLengthIndex): return -1
  let textLengthValue = input[textLengthIndex]
  if textLengthValue < 0 or textLengthValue > int64(MaxTextLength) or textLengthValue mod 2 != 0:
    return -1
  let textLength = int(textLengthValue)
  let textStart = textLengthIndex + 1
  if length != csize_t(textStart + textLength): return -1

  var seen: array[26, bool]
  var square: array[25, uint8]
  var squareLength = 0
  for index in 0 ..< keyLength:
    let value = input[2 + index]
    if value < 65 or value > 90 or value == 74: return -1
    let letter = uint8(value)
    let slot = int(letter - uint8(ord('A')))
    if not seen[slot]:
      seen[slot] = true
      square[squareLength] = letter
      inc squareLength
  for character in Alphabet:
    let letter = uint8(ord(character))
    let slot = int(letter - uint8(ord('A')))
    if not seen[slot]:
      seen[slot] = true
      square[squareLength] = letter
      inc squareLength

  var positions: array[26, uint8]
  for index, letter in square:
    positions[int(letter - uint8(ord('A')))] = uint8(index)

  var previous = 0'u8
  for index in 0 ..< textLength:
    let value = input[textStart + index]
    if value < 65 or value > 90 or value == 74: return -1
    let letter = uint8(value)
    if operation == 0 and index > 0 and letter == previous: return -1
    previous = letter

  var hash = FnvOffsetBasis
  let shift = if operation == 0: 1 else: -1
  var index = 0
  while index < textLength:
    let first = uint8(input[textStart + index])
    let second = uint8(input[textStart + index + 1])
    let position1 = int(positions[int(first - uint8(ord('A')))])
    let position2 = int(positions[int(second - uint8(ord('A')))])
    let row1 = position1 div 5
    let column1 = position1 mod 5
    let row2 = position2 div 5
    let column2 = position2 mod 5
    var result1, result2: uint8
    if row1 == row2:
      let next1 = (column1 + shift + 5) mod 5
      let next2 = (column2 + shift + 5) mod 5
      result1 = square[row1 * 5 + next1]
      result2 = square[row2 * 5 + next2]
    elif column1 == column2:
      let next1 = (row1 + shift + 5) mod 5
      let next2 = (row2 + shift + 5) mod 5
      result1 = square[next1 * 5 + column1]
      result2 = square[next2 * 5 + column2]
    else:
      result1 = square[row1 * 5 + column2]
      result2 = square[row2 * 5 + column1]
    hash = (hash xor uint64(result1)) *% FnvPrime
    hash = (hash xor uint64(result2)) *% FnvPrime
    index += 2
  int64(hash and Low63Mask)
