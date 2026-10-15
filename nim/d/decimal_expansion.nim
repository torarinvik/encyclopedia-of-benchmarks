proc writeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  var bits = if value < 0: high(uint64) else: uint64(value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8(bits and 0xff'u64)
    bits = bits shr 8

proc decimal_expansion*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "decimal_expansion".} =
  if values.isNil or length != 3: return -1
  let numerator = values[0]
  let denominator = values[1]
  let base = values[2]
  if numerator < 0 or denominator < 1 or denominator > 256 or
      numerator > denominator or base < 2 or base > 10: return -1

  var digits: array[255, uint8]
  var firstSeen: array[256, int64]
  for index in 0 ..< firstSeen.len: firstSeen[index] = -1
  var digitCount = 0
  var cycleStart = -1'i64
  var remainder = numerator
  while remainder != 0 and numerator != denominator:
    let remainderIndex = int(remainder)
    if firstSeen[remainderIndex] >= 0:
      cycleStart = firstSeen[remainderIndex]
      break
    firstSeen[remainderIndex] = int64(digitCount)
    let scaled = remainder * base
    digits[digitCount] = uint8(scaled div denominator)
    inc digitCount
    remainder = scaled mod denominator

  let required = 24 + digitCount
  if output.isNil or int(capacity) < required: return -2
  writeI64Le(output, 0, if numerator == denominator: 1 else: 0)
  writeI64Le(output, 8, int64(digitCount))
  writeI64Le(output, 16, cycleStart)
  for index in 0 ..< digitCount: output[24 + index] = digits[index]
  int64(required)
