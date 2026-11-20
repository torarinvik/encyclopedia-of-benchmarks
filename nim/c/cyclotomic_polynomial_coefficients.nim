const CyclotomicMaxN = 32
const CyclotomicMaxInputLength = 2
type I64Array = ptr UncheckedArray[int64]
type ByteArray = ptr UncheckedArray[uint8]

proc storeCyclotomicI64Le(output: ByteArray, offset: int, value: int64) =
  var bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8(bits and 255)
    bits = bits shr 8

proc cyclotomic_polynomial_coefficients*(input: I64Array, length: csize_t,
    output: ByteArray, capacity: csize_t): int64
    {.cdecl, exportc: "cyclotomic_polynomial_coefficients".} =
  if input.isNil or length == 0 or length > csize_t(CyclotomicMaxInputLength): return -1
  let nValue = input[0]
  if nValue < 1 or nValue > int64(CyclotomicMaxN) or length != 1: return -1
  let n = int(nValue)

  var polynomials: array[CyclotomicMaxN + 1, array[CyclotomicMaxN + 1, int64]]
  var degrees: array[CyclotomicMaxN + 1, int]
  polynomials[1][0] = -1
  polynomials[1][1] = 1
  degrees[1] = 1
  for k in 2 .. n:
    var divisor: array[CyclotomicMaxN + 1, int64]
    divisor[0] = 1
    var divisorDegree = 0
    for d in 1 ..< k:
      if k mod d != 0: continue
      var product: array[CyclotomicMaxN + 1, int64]
      for i in 0 .. divisorDegree:
        for j in 0 .. degrees[d]:
          product[i + j] += divisor[i] * polynomials[d][j]
      divisorDegree += degrees[d]
      for i in 0 .. divisorDegree: divisor[i] = product[i]

    var remainder: array[CyclotomicMaxN + 1, int64]
    remainder[0] = -1
    remainder[k] = 1
    let quotientDegree = k - divisorDegree
    degrees[k] = quotientDegree
    for q in countdown(quotientDegree, 0):
      let leading = remainder[divisorDegree + q]
      polynomials[k][q] = leading
      for j in 0 .. divisorDegree:
        remainder[q + j] -= leading * divisor[j]

  let coefficientCount = degrees[n] + 1
  let required = coefficientCount * 8
  if output.isNil or capacity < csize_t(required): return -2
  for index in 0 ..< coefficientCount:
    storeCyclotomicI64Le(output, 8 * index, polynomials[n][index])
  int64(required)
