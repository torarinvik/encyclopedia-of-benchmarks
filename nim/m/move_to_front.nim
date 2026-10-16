const MaxAlphabetLength = 32
const MaxTextLength = 128

proc move_to_front*(values: ptr UncheckedArray[int64], length: csize_t,
                    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "move_to_front".} =
  if values.isNil or length < 3 or length > 164: return -1
  let mode = values[0]
  let alphabetLength = values[1]
  let textLength = values[2]
  if (mode != 0 and mode != 1) or alphabetLength < 0 or alphabetLength > MaxAlphabetLength or
      textLength < 0 or textLength > MaxTextLength or
      length != 3 + csize_t(alphabetLength + textLength): return -1
  var alphabet: array[MaxAlphabetLength, int64]
  var result: array[MaxTextLength, uint8]
  for i in 0 ..< int(alphabetLength):
    let symbol = values[3 + i]
    if symbol < 0 or symbol > 127: return -1
    for j in 0 ..< i:
      if alphabet[j] == symbol: return -1
    alphabet[i] = symbol
  var resultLength = 0
  if mode == 0:
    if textLength > 0 and alphabetLength == 0: return -1
    for i in 0 ..< int(textLength):
      let symbol = values[3 + int(alphabetLength) + i]
      if symbol < 0 or symbol > 127: return -1
      var position = 0
      while position < int(alphabetLength) and alphabet[position] != symbol: inc position
      if position == int(alphabetLength): return -1
      result[resultLength] = uint8(position)
      inc resultLength
      var j = position
      while j > 0:
        alphabet[j] = alphabet[j - 1]
        dec j
      alphabet[0] = symbol
  elif alphabetLength > 0:
    for i in 0 ..< int(textLength):
      let index = values[3 + int(alphabetLength) + i]
      if index < 0 or index >= alphabetLength: return -1
      let position = int(index)
      let symbol = alphabet[position]
      result[resultLength] = uint8(symbol)
      inc resultLength
      var j = position
      while j > 0:
        alphabet[j] = alphabet[j - 1]
        dec j
      alphabet[0] = symbol
  if capacity < csize_t(resultLength) or (resultLength > 0 and output.isNil): return -2
  for i in 0 ..< resultLength: output[i] = result[i]
  int64(resultLength)
