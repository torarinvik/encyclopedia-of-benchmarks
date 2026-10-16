## Count A/C/G/T and return all four counts as an ASCII string.
const MaxSequenceLength = 1000

proc decimalLength(value: int64): int =
  var current = value
  result = 1
  while current >= 10:
    current = current div 10
    inc result

proc writeDecimal(output: ptr UncheckedArray[uint8], offset: int, value: int64): int =
  var divisor = 1'i64
  while value div divisor >= 10: divisor *= 10
  var current = value
  result = offset
  while divisor > 0:
    output[result] = uint8(48'i64 + current div divisor)
    inc result
    current = current mod divisor
    divisor = divisor div 10

proc count_nucleotide*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "count_nucleotide".} =
  if values == nil or length < 1 or length > 1001: return -1
  let countValue = values[0]
  if countValue < 0 or countValue > MaxSequenceLength or length != csize_t(countValue + 1): return -1
  var countA = 0'i64
  var countC = 0'i64
  var countG = 0'i64
  var countT = 0'i64
  for i in 0 ..< int(countValue):
    let codepoint = values[1 + i]
    if codepoint < 0 or codepoint > 127: return -1
    if codepoint == 65: inc countA
    elif codepoint == 67: inc countC
    elif codepoint == 71: inc countG
    elif codepoint == 84: inc countT
  let outputLength = decimalLength(countA) + decimalLength(countC) + decimalLength(countG) + decimalLength(countT) + 3
  if output == nil or capacity < csize_t(outputLength): return -2
  var offset = writeDecimal(output, 0, countA); output[offset] = uint8(ord(' ')); inc offset
  offset = writeDecimal(output, offset, countC); output[offset] = uint8(ord(' ')); inc offset
  offset = writeDecimal(output, offset, countG); output[offset] = uint8(ord(' ')); inc offset
  offset = writeDecimal(output, offset, countT)
  int64(offset)
