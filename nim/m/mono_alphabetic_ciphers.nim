const
  MaxParseableInputLength = 157
  FnvOffsetBasis = 14695981039346656037'u64
  FnvPrime = 1099511628211'u64
  Mask63 = 0x7fffffffffffffff'u64

type I64Input = ptr UncheckedArray[int64]

proc mono_alphabetic_ciphers*(input: I64Input, inputLength: csize_t): int64
    {.cdecl, exportc: "mono_alphabetic_ciphers".} =
  if input == nil or inputLength < 2 or inputLength > csize_t(MaxParseableInputLength): return -1
  let operation = input[0]
  let rawTextLength = input[1]
  if operation notin [0'i64, 1'i64] or rawTextLength < 0 or rawTextLength > 128: return -1
  let textLength = int(rawTextLength)
  if int(inputLength) != 28 + textLength: return -1

  var seen: array[26, bool]
  var inverse: array[26, int]
  for i in 0 ..< 26:
    let value = input[2 + i]
    if value < 65 or value > 90: return -1
    let index = int(value - 65)
    if seen[index]: return -1
    seen[index] = true
    inverse[index] = i
  for i in 0 ..< textLength:
    if input[28 + i] < 32 or input[28 + i] > 126: return -1

  var hash = FnvOffsetBasis
  let lengthWord = uint64(textLength)
  for byte in 0 ..< 8:
    hash = (hash xor ((lengthWord shr (byte * 8)) and 255'u64)) *% FnvPrime
  for i in 0 ..< textLength:
    let value = input[28 + i]
    var mapped = value
    if (65 <= value and value <= 90) or (97 <= value and value <= 122):
      let lower = 97 <= value and value <= 122
      let letter = int(if lower: value - 97 else: value - 65)
      let position = if operation == 0: inverse[letter] else: letter
      let target = if operation == 0: 65 + int64(position) else: input[2 + position]
      mapped = if lower: target + 32 else: target
    hash = (hash xor uint64(mapped)) *% FnvPrime
  int64(hash and Mask63)
