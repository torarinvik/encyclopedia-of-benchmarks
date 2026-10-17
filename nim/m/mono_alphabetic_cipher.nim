const
  MaxParseableInputLength = 183
  FnvOffsetBasis = 14695981039346656037'u64
  FnvPrime = 1099511628211'u64
  Mask63 = 0x7fffffffffffffff'u64

type I64Input = ptr UncheckedArray[int64]

proc mono_alphabetic_cipher*(input: I64Input, inputLength: csize_t): int64
    {.cdecl, exportc: "mono_alphabetic_cipher".} =
  if input == nil or inputLength < 2 or inputLength > csize_t(MaxParseableInputLength): return -1
  let operation = input[0]
  let rawTextLength = input[1]
  if operation notin [0'i64, 1'i64] or rawTextLength < 0 or rawTextLength > 128: return -1
  let textLength = int(rawTextLength)
  if int(inputLength) != 54 + textLength: return -1

  var keySeen, alphabetSeen: array[26, bool]
  var keyInverse, alphabetInverse: array[26, int]
  for i in 0 ..< 26:
    let keyValue = input[2 + i]
    let alphabetValue = input[28 + i]
    if keyValue < 65 or keyValue > 90 or alphabetValue < 65 or alphabetValue > 90: return -1
    let keyIndex = int(keyValue - 65)
    let alphabetIndex = int(alphabetValue - 65)
    if keySeen[keyIndex] or alphabetSeen[alphabetIndex]: return -1
    keySeen[keyIndex] = true
    alphabetSeen[alphabetIndex] = true
    keyInverse[keyIndex] = i
    alphabetInverse[alphabetIndex] = i
  var outputLength = 0
  for i in 0 ..< textLength:
    let value = input[54 + i]
    if not (value == 32 or (48 <= value and value <= 57) or
        (65 <= value and value <= 90) or (97 <= value and value <= 122)): return -1
    if value < 48 or value > 57: inc outputLength

  var hash = FnvOffsetBasis
  let lengthWord = uint64(outputLength)
  for byte in 0 ..< 8:
    hash = (hash xor ((lengthWord shr (byte * 8)) and 255'u64)) *% FnvPrime
  for i in 0 ..< textLength:
    let value = input[54 + i]
    if 48 <= value and value <= 57: continue
    var mapped: int64 = value
    if value != 32:
      let lower = 97 <= value and value <= 122
      let letter = int(if lower: value - 97 else: value - 65)
      let position = if operation == 0: alphabetInverse[letter] else: keyInverse[letter]
      let target = if operation == 0: input[2 + position] else: input[28 + position]
      mapped = if lower: target + 32 else: target
    hash = (hash xor uint64(mapped)) *% FnvPrime
  int64(hash and Mask63)
