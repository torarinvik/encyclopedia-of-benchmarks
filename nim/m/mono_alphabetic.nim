const
  MaxTextLength = 256
  MaxParseableInputLength = 285
  FnvOffsetBasis = 14695981039346656037'u64
  FnvPrime = 1099511628211'u64
  Mask63 = 0x7fffffffffffffff'u64

type I64Input = ptr UncheckedArray[int64]

proc mono_alphabetic*(input: I64Input, inputLength: csize_t): int64
    {.cdecl, exportc: "mono_alphabetic".} =
  if input == nil or inputLength < 2 or inputLength > csize_t(MaxParseableInputLength): return -1
  let operation = input[0]
  let rawTextLength = input[1]
  if operation notin [0'i64, 1'i64] or rawTextLength < 1 or rawTextLength > int64(MaxTextLength): return -1
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
    if input[28 + i] < 65 or input[28 + i] > 90: return -1

  var hash = FnvOffsetBasis
  var lengthWord = uint64(textLength)
  for byte in 0 ..< 8:
    hash = (hash xor ((lengthWord shr (8 * byte)) and 255'u64)) *% FnvPrime
  for i in 0 ..< textLength:
    let index = int(input[28 + i] - 65)
    let mapped = if operation == 0: input[2 + index] else: 65 + int64(inverse[index])
    hash = (hash xor uint64(mapped)) *% FnvPrime
  int64(hash and Mask63)
