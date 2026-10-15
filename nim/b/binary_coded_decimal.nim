## Write the prefixed four-bit-per-decimal-digit BCD representation.
proc binary_coded_decimal*(value: int64, output: ptr UncheckedArray[uint8],
    outputCapacity: csize_t): int64 {.cdecl, exportc: "binary_coded_decimal".} =
  if value < -2_147_483_648'i64 or value > 2_147_483_647'i64: return -1
  var normalized = value
  if normalized < 0: normalized = 0

  var digits: array[10, uint8]
  var digitCount = 0
  var remaining = normalized
  while remaining > 0:
    digits[digitCount] = uint8(remaining mod 10)
    inc digitCount
    remaining = remaining div 10
  if digitCount == 0:
    digits[0] = 0
    digitCount = 1

  let outputLength = 2 + digitCount * 4
  if output == nil or outputCapacity < csize_t(outputLength): return -2
  output[0] = uint8(ord('0'))
  output[1] = uint8(ord('b'))
  var position = 2
  while digitCount > 0:
    dec digitCount
    let digit = digits[digitCount]
    for bit in countdown(3, 0):
      output[position] = uint8(ord('0') + int((digit shr bit) and 1))
      inc position
  int64(outputLength)
