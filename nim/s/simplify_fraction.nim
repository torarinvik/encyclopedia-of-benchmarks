const MaxAbsComponent = 1_000_000'i64
const OutputBytes = 16

proc putI64Le(output: var array[OutputBytes, uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xff'u64)

proc simplify_fraction*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "simplify_fraction".} =
  if input == nil or inputLength != 2: return -1
  let numerator = input[0]
  let denominator = input[1]
  if numerator < -MaxAbsComponent or numerator > MaxAbsComponent or
      denominator < -MaxAbsComponent or denominator > MaxAbsComponent or denominator == 0: return -1
  var a = uint64(if numerator < 0: -numerator else: numerator)
  var b = uint64(if denominator < 0: -denominator else: denominator)
  while b != 0:
    let remainder = a mod b
    a = b
    b = remainder
  let divisor = int64(a)
  let reducedNumerator = numerator div divisor
  let reducedDenominator = denominator div divisor
  var staged: array[OutputBytes, uint8]
  putI64Le(staged, 0, reducedNumerator)
  putI64Le(staged, 8, reducedDenominator)
  if output == nil or capacity < csize_t(OutputBytes): return -2
  for i in 0 ..< OutputBytes: output[i] = staged[i]
  int64(OutputBytes)
