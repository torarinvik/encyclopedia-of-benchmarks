const MaxComponent = 100_000'i64
const OutputBytes = 16

proc storeI64Le(output: ptr UncheckedArray[uint8], position: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[position + byte] = uint8((bits shr (byte * 8)) and 255'u64)

proc complex_arithmetic*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "complex_arithmetic".} =
  if input == nil or length != 5: return -1
  let operation = input[0]
  let ar = input[1]
  let ai = input[2]
  let br = input[3]
  let bi = input[4]
  if operation < 0 or operation > 5 or ar < -MaxComponent or ar > MaxComponent or
      ai < -MaxComponent or ai > MaxComponent or br < -MaxComponent or
      br > MaxComponent or bi < -MaxComponent or bi > MaxComponent: return -1

  var realResult = 0'i64
  var imaginaryResult = 0'i64
  case operation
  of 0:
    realResult = ar + br
    imaginaryResult = ai + bi
  of 1:
    realResult = ar - br
    imaginaryResult = ai - bi
  of 2:
    realResult = ar * br - ai * bi
    imaginaryResult = ar * bi + ai * br
  of 3:
    let denominator = br * br + bi * bi
    if denominator == 0: return -1
    let realNumerator = ar * br + ai * bi
    let imaginaryNumerator = ai * br - ar * bi
    if realNumerator mod denominator != 0 or imaginaryNumerator mod denominator != 0: return -1
    realResult = realNumerator div denominator
    imaginaryResult = imaginaryNumerator div denominator
  of 4:
    realResult = ar
    imaginaryResult = -ai
  else:
    if ar == br and ai == bi: realResult = 1

  if outputCapacity < csize_t(OutputBytes) or output == nil: return -2
  storeI64Le(output, 0, realResult)
  storeI64Le(output, 8, imaginaryResult)
  2
