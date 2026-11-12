const
  Modulus = 998_244_353'i64
  MaxFactors = 6
  MaxCoefficients = 25
  MaxInput = 38

type
  PolynomialBuffer = array[MaxFactors * MaxCoefficients, int64]
  LengthBuffer = array[MaxFactors, int]

proc storeLe(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc product_of_polynomial_sequence*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "product_of_polynomial_sequence".} =
  if input.isNil or length < csize_t(1) or length > csize_t(MaxInput): return -1
  if input[0] < 0 or input[0] > MaxFactors.int64: return -1
  let count = int(input[0])
  var polynomials: PolynomialBuffer
  var polyLengths: LengthBuffer
  var cursor = 1
  var degreeSum = 0
  for p in 0 ..< count:
    if cursor >= int(length) or input[cursor] < 0 or input[cursor] > 4: return -1
    let degree = int(input[cursor])
    inc cursor
    if cursor + degree + 1 > int(length): return -1
    for i in 0 .. degree:
      let coefficient = input[cursor + i]
      if coefficient < 0 or coefficient >= Modulus: return -1
      polynomials[p * MaxCoefficients + i] = coefficient
    if polynomials[p * MaxCoefficients + degree] == 0: return -1
    polyLengths[p] = degree + 1
    degreeSum += degree
    cursor += degree + 1
  if cursor != int(length): return -1

  let resultLength = degreeSum + 1
  let bytes = 8 * resultLength
  if output.isNil or capacity < csize_t(bytes): return -2
  if count == 0:
    storeLe(output, 0, 1)
    return 8

  var scratch: array[MaxCoefficients, int64]
  var active = count
  while active > 1:
    var nextCount = 0
    var i = 0
    while i < active:
      let destination = nextCount * MaxCoefficients
      if i + 1 == active:
        let source = i * MaxCoefficients
        for j in 0 ..< polyLengths[i]:
          polynomials[destination + j] = polynomials[source + j]
        polyLengths[nextCount] = polyLengths[i]
      else:
        let leftStart = i * MaxCoefficients
        let rightStart = (i + 1) * MaxCoefficients
        let leftLength = polyLengths[i]
        let rightLength = polyLengths[i + 1]
        let productLength = leftLength + rightLength - 1
        for j in 0 ..< productLength: scratch[j] = 0
        for a in 0 ..< leftLength:
          for b in 0 ..< rightLength:
            let slot = a + b
            scratch[slot] = (scratch[slot] +
              polynomials[leftStart + a] * polynomials[rightStart + b]) mod Modulus
        for j in 0 ..< productLength:
          polynomials[destination + j] = scratch[j]
        polyLengths[nextCount] = productLength
      inc nextCount
      i += 2
    active = nextCount

  for i in 0 ..< resultLength: storeLe(output, 8 * i, polynomials[i])
  int64(bytes)
