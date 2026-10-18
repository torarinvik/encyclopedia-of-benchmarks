const MaxDigits = 64
const MaxOutputDigits = 1664

proc trim(value: var seq[uint32]) =
  while value.len > 0 and value[^1] == 0'u32: value.setLen(value.len - 1)

proc fromSmall(valueInput, base: uint32): seq[uint32] =
  var value = valueInput
  while value > 0:
    result.add(value mod base)
    value = value div base

proc add(left: var seq[uint32], right: openArray[uint32], base: uint32) =
  var index = 0
  var carry = 0'u64
  while index < right.len or carry != 0:
    let a = if index < left.len: uint64(left[index]) else: 0'u64
    let b = if index < right.len: uint64(right[index]) else: 0'u64
    let total = carry + a + b
    if index == left.len: left.add(0'u32)
    left[index] = uint32(total mod uint64(base))
    carry = total div uint64(base)
    inc index
  if left.len < right.len:
    for i in left.len ..< right.len: left.add(right[i])

proc multiply(left, right: openArray[uint32], base: uint32): seq[uint32] =
  if left.len == 0 or right.len == 0: return @[]
  result = newSeq[uint32](left.len + right.len)
  for i in 0 ..< left.len:
    var carry = 0'u64
    for j in 0 ..< right.len:
      let at = i + j
      let product = uint64(left[i]) * uint64(right[j]) + uint64(result[at]) + carry
      result[at] = uint32(product mod uint64(base))
      carry = product div uint64(base)
    var at = i + right.len
    while carry != 0:
      let total = uint64(result[at]) + carry
      result[at] = uint32(total mod uint64(base))
      carry = total div uint64(base)
      inc at
      if at > result.len: result.setLen(at)
  trim(result)

proc power(factorInput: seq[uint32], exponentInput: int, base: uint32): seq[uint32] =
  var factor = factorInput
  var exponent = exponentInput
  result = fromSmall(1, base)
  while exponent > 0:
    if (exponent and 1) != 0: result = multiply(result, factor, base)
    exponent = exponent shr 1
    if exponent > 0: factor = multiply(factor, factor, base)

proc convertBase(digits: openArray[uint32], sourceBase, targetBase: uint32): seq[uint32] =
  if digits.len == 0: return @[]
  if sourceBase == targetBase:
    for digit in digits: result.add(digit)
    return
  if digits.len == 1: return fromSmall(digits[0], targetBase)
  let middle = digits.len div 2
  var low = convertBase(digits.toOpenArray(0, middle - 1), sourceBase, targetBase)
  let high = convertBase(digits.toOpenArray(middle, digits.high), sourceBase, targetBase)
  let scale = power(fromSmall(sourceBase, targetBase), middle, targetBase)
  let shifted = multiply(high, scale, targetBase)
  add(low, shifted, targetBase)
  low

proc uint_convert_base*(input: ptr UncheckedArray[int64], length: csize_t,
                        output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "uint_convert_base".} =
  if input.isNil or length < 3 or length > csize_t(MaxDigits + 4): return -1
  let sourceValue = input[0]
  let targetValue = input[1]
  let countValue = input[2]
  if sourceValue < 2 or sourceValue > (1'i64 shl 26) or targetValue < 2 or targetValue > (1'i64 shl 26) or
      countValue < 0 or countValue > MaxDigits or length != csize_t(countValue + 3): return -1
  let sourceBase = uint32(sourceValue)
  let targetBase = uint32(targetValue)
  let count = int(countValue)
  var digits = newSeq[uint32](count)
  for i in 0 ..< count:
    if input[i + 3] < 0 or input[i + 3] >= sourceValue: return -1
    digits[i] = uint32(input[i + 3])
  if count > 0 and digits[count - 1] == 0: return -1
  let converted = convertBase(digits, sourceBase, targetBase)
  if converted.len > MaxOutputDigits: return -1
  let byteCount = converted.len * 4
  if output.isNil or capacity < csize_t(byteCount): return -2
  for i in 0 ..< converted.len:
    for byte in 0 ..< 4: output[i * 4 + byte] = uint8((converted[i] shr (byte * 8)) and 0xff'u32)
  int64(byteCount)
