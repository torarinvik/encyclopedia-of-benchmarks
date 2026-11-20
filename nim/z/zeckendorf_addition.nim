type
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]

const MaxBits = 64
const MaxParseable = 131
const MaxOutput = 66

proc canonical(bits: I64Input, length: int): bool =
  if length == 1 and bits[0] == 0: return true
  if length == 0 or bits[0] != 1: return false
  for i in 0..<length:
    if bits[i] != 0 and bits[i] != 1: return false
    if i + 1 < length and bits[i] == 1 and bits[i + 1] == 1: return false
  true

proc stageOne(d: var array[MaxOutput, uint8], n: int) =
  for i in 0..<max(0, n - 3):
    if d[i] == 0 and d[i + 1] == 2 and d[i + 2] == 0:
      d[i] = 1; d[i + 1] = 0; d[i + 2] = 0; inc d[i + 3]
    elif d[i] == 0 and d[i + 1] == 3 and d[i + 2] == 0:
      d[i] = 1; d[i + 1] = 1; d[i + 2] = 0; inc d[i + 3]
    elif d[i] == 0 and d[i + 1] == 2 and d[i + 2] == 1:
      d[i] = 1; d[i + 1] = 1; d[i + 2] = 0
    elif d[i] == 0 and d[i + 1] == 1 and d[i + 2] == 2:
      d[i] = 1; d[i + 1] = 0; d[i + 2] = 1
  if n >= 3 and d[n - 3] == 0 and d[n - 2] == 3 and d[n - 1] == 0:
    d[n - 3] = 1; d[n - 2] = 1; d[n - 1] = 1
  elif n >= 3 and d[n - 3] == 0 and d[n - 2] == 2 and d[n - 1] == 0:
    d[n - 3] = 1; d[n - 2] = 0; d[n - 1] = 1
  elif n >= 4 and d[n - 4] == 0 and d[n - 3] == 1 and d[n - 2] == 2 and d[n - 1] == 0:
    d[n - 4] = 1; d[n - 3] = 0; d[n - 2] = 1; d[n - 1] = 0
  elif n >= 3 and d[n - 3] == 0 and d[n - 2] == 2 and d[n - 1] == 1:
    d[n - 3] = 1; d[n - 2] = 1; d[n - 1] = 0
  if n >= 2 and d[n - 2] == 0 and d[n - 1] == 3:
    d[n - 2] = 1; d[n - 1] = 1
  elif n >= 2 and d[n - 2] == 0 and d[n - 1] == 2:
    d[n - 2] = 1; d[n - 1] = 0
  elif n >= 3 and d[n - 3] == 0 and d[n - 2] == 1 and d[n - 1] == 2:
    d[n - 3] = 1; d[n - 2] = 0; d[n - 1] = 1

proc zeckendorf_addition*(input: I64Input, length: csize_t, output: U8Output,
    outputCapacity: csize_t): int64 {.cdecl, exportc: "zeckendorf_addition".} =
  if input.isNil or length < 4 or length > MaxParseable: return -1
  let firstNValue = input[0]
  if firstNValue < 1 or firstNValue > MaxBits: return -1
  let firstN = int(firstNValue)
  let secondNIndex = firstN + 1
  if secondNIndex >= int(length): return -1
  let secondNValue = input[secondNIndex]
  if secondNValue < 1 or secondNValue > MaxBits: return -1
  let secondN = int(secondNValue)
  if int(length) != secondNIndex + secondN + 1: return -1
  let first = cast[I64Input](addr input[1])
  let second = cast[I64Input](addr input[secondNIndex + 1])
  if not canonical(first, firstN) or not canonical(second, secondN): return -1

  let width = max(firstN, secondN)
  let firstOffset = width - firstN
  let secondOffset = width - secondN
  var digits: array[MaxOutput, uint8]
  var digitCount = width + 1
  for i in 0..<width:
    let a = if i < firstOffset: 0'u8 else: uint8(first[i - firstOffset])
    let b = if i < secondOffset: 0'u8 else: uint8(second[i - secondOffset])
    digits[i + 1] = a + b
  stageOne(digits, digitCount)
  for i in countdown(digitCount - 1, 0): digits[i + 1] = digits[i]
  digits[0] = 0
  inc digitCount
  for i in countdown(digitCount - 3, 0):
    if digits[i] == 0 and digits[i + 1] == 1 and digits[i + 2] == 1:
      digits[i] = 1; digits[i + 1] = 0; digits[i + 2] = 0
  for i in 0 ..< digitCount - 2:
    if digits[i] == 0 and digits[i + 1] == 1 and digits[i + 2] == 1:
      digits[i] = 1; digits[i + 1] = 0; digits[i + 2] = 0
  var firstOutput = 0
  while firstOutput + 1 < digitCount and digits[firstOutput] == 0: inc firstOutput
  let required = digitCount - firstOutput
  if output.isNil or outputCapacity < csize_t(required): return -2
  for i in 0..<required: output[i] = uint8('0') + digits[firstOutput + i]
  int64(required)
