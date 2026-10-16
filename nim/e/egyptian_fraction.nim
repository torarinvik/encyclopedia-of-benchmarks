## Return source-ordered unit-fraction denominators as little-endian i32s.
proc egyptian_fraction*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "egyptian_fraction".} =
  if input == nil or length != 2: return -1
  var numerator = input[0]
  var denominator = input[1]
  if numerator < 0 or denominator < 1 or denominator > 10 or numerator > denominator: return -1

  var terms: array[10, uint32]
  var count = 0
  while numerator != 0:
    var unitDenominator = denominator div numerator
    if denominator mod numerator != 0: inc unitDenominator
    terms[count] = uint32(unitDenominator)
    inc count
    numerator = numerator * unitDenominator - denominator
    denominator = denominator * unitDenominator
  let required = count * 4
  if outputCapacity < csize_t(required) or (required > 0 and output == nil): return -2
  for index in 0 ..< count:
    let value = terms[index]
    for byte in 0 ..< 4: output[index * 4 + byte] = uint8((value shr (8 * byte)) and 255)
  int64(required)
