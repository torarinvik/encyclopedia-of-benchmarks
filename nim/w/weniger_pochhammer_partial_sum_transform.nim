const MinWords = 7
const MaxWords = 17
const OutputBytes = 16

proc wenigerGcd(aInput, bInput: int64): int64 =
  var a = aInput
  var b = bInput
  while b != 0:
    let remainder = a mod b
    a = b
    b = remainder
  a

proc storeI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc weniger_pochhammer_partial_sum_transform*(input: ptr UncheckedArray[int64],
    inputLength: csize_t, output: ptr UncheckedArray[uint8],
    outputCapacity: csize_t): int64 {.cdecl, exportc: "weniger_pochhammer_partial_sum_transform".} =
  if input == nil or inputLength < MinWords or inputLength > MaxWords: return -1
  let n0 = input[0]
  let k0 = input[1]
  if n0 < 0 or n0 > 8 or k0 < 3 or k0 > 4: return -1
  let n = int(n0)
  let k = int(k0)
  if inputLength != csize_t(n + k + 4): return -1
  let termCount = n + k + 2
  for i in 0 ..< termCount:
    let value = input[i + 2]
    if value == 0 or value < -3 or value > 3: return -1

  var product = 1'i64
  for r in 0 .. k:
    product *= input[n + r + 3]
  var numerator = 0'i64
  var denominator = 0'i64
  for j in 0 .. k:
    var choose = 1'i64
    for r in 1 ..< j + 1:
      choose = choose * int64(k - r + 1) div int64(r)
    var rising = 1'i64
    for offset in 0 ..< k - 1:
      rising *= int64(n + j + 1 + offset)
    let term = input[n + j + 3]
    var weight = choose * rising * (product div term)
    if (j and 1) != 0: weight = -weight
    var partial = 0'i64
    for index in 0 .. n + j:
      partial += input[index + 2]
    numerator += weight * partial
    denominator += weight
  if denominator == 0: return -1
  if denominator < 0:
    numerator = -numerator
    denominator = -denominator
  let divisor = wenigerGcd(abs(numerator), denominator)
  numerator = numerator div divisor
  denominator = denominator div divisor
  if output == nil or outputCapacity < csize_t(OutputBytes): return -2
  storeI64(output, 0, numerator)
  storeI64(output, 8, denominator)
  int64(OutputBytes)
