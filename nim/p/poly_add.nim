const MaxTerms = 16
const MaxInputValues = 67
const MaxOutputTerms = 32

type I64Array = ptr UncheckedArray[int64]
type ByteArray = ptr UncheckedArray[uint8]
type TermArray = array[MaxOutputTerms, int64]

proc putI64Le(output: ByteArray, offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc validateTerms(input: I64Array, start, count: int): bool =
  var previousDegree = 64'i64
  for i in 0 ..< count:
    let coefficient = input[start + 2 * i]
    let degree = input[start + 2 * i + 1]
    if coefficient < -1_000_000 or coefficient > 1_000_000 or
        degree < 0 or degree > 63 or degree >= previousDegree:
      return false
    previousDegree = degree
  true

proc poly_add*(input: I64Array, length: csize_t, output: ByteArray,
    outputCapacity: csize_t): int64 {.cdecl, exportc: "poly_add".} =
  if input == nil or length < 2 or length > csize_t(MaxInputValues): return -1
  let countAValue = input[0]
  if countAValue < 1 or countAValue > MaxTerms: return -1
  let countA = int(countAValue)
  let countBIndex = 1 + 2 * countA
  if length <= csize_t(countBIndex): return -1
  let countBValue = input[countBIndex]
  if countBValue < 1 or countBValue > MaxTerms: return -1
  let countB = int(countBValue)
  if length != csize_t(2 + 2 * (countA + countB)): return -1

  let startA = 1
  let startB = countBIndex + 1
  if not validateTerms(input, startA, countA) or not validateTerms(input, startB, countB): return -1

  var coefficients: TermArray
  var degrees: TermArray
  var i = 0
  var j = 0
  var terms = 0
  while i < countA and j < countB:
    let coefficientA = input[startA + 2 * i]
    let degreeA = input[startA + 2 * i + 1]
    let coefficientB = input[startB + 2 * j]
    let degreeB = input[startB + 2 * j + 1]
    if degreeA > degreeB:
      coefficients[terms] = coefficientA
      degrees[terms] = degreeA
      inc terms
      inc i
    elif degreeA < degreeB:
      coefficients[terms] = coefficientB
      degrees[terms] = degreeB
      inc terms
      inc j
    else:
      coefficients[terms] = coefficientA + coefficientB
      degrees[terms] = degreeA
      inc terms
      inc i
      inc j
  while i < countA:
    coefficients[terms] = input[startA + 2 * i]
    degrees[terms] = input[startA + 2 * i + 1]
    inc terms
    inc i
  while j < countB:
    coefficients[terms] = input[startB + 2 * j]
    degrees[terms] = input[startB + 2 * j + 1]
    inc terms
    inc j

  let required = terms * 16
  if output == nil or outputCapacity < csize_t(required): return -2
  for term in 0 ..< terms:
    putI64Le(output, term * 16, coefficients[term])
    putI64Le(output, term * 16 + 8, degrees[term])
  int64(required)
