const MaxCount = 64
const MaxParseableInputLength = 3
const MaxOutputBytes = 8 * MaxCount

proc generateNthTerm(index: int64): int64 =
  if index == 0 or index == 1: return index
  if index mod 2 == 0: return 4 * generateNthTerm(index div 2)
  4 * generateNthTerm(index div 2) + 1

proc putI64Le(value: int64, output: ptr UncheckedArray[uint8], offset: int) =
  var bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8(bits and 255)
    bits = bits shr 8

proc sequence*(values: ptr UncheckedArray[int64], length: csize_t,
               output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "sequence".} =
  if values.isNil or length < 1 or length > MaxParseableInputLength.csize_t: return -1
  if length != 1 or values[0] < -MaxCount or values[0] > MaxCount: return -1
  if values[0] <= 0: return 0

  let count = int(values[0])
  let required = count * 8
  if output.isNil or outputCapacity < required.csize_t or required > MaxOutputBytes: return -2
  for index in 0 ..< count:
    putI64Le(generateNthTerm(index.int64), output, index * 8)
  required.int64
