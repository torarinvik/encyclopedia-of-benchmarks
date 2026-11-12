const
  Modulus = 998_244_353'i64
  MaxN = 64
  MaxInput = 131
  MaxOutputBytes = 536

type Poly = array[MaxN, int64]

proc powerMod(baseInput, exponentInput: int64): int64 =
  var base = baseInput
  var exponent = exponentInput
  var result = 1'i64
  while exponent > 0:
    if (exponent and 1) != 0: result = result * base mod Modulus
    base = base * base mod Modulus
    exponent = exponent shr 1
  result

proc trim(poly: Poly, lengthInput: int): int =
  var length = lengthInput
  while length > 0 and poly[length - 1] == 0: dec length
  length

proc storeLe(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc division_of_polynomials*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "division_of_polynomials".} =
  if input.isNil or length < csize_t(4) or length > csize_t(MaxInput): return -1
  let nValue = input[0]
  let mValue = input[1]
  if nValue < 1 or nValue > MaxN.int64 or mValue < 1 or mValue > MaxN.int64: return -1
  let n = int(nValue)
  let m = int(mValue)
  if int(length) != 2 + n + m: return -1

  var work, quotient: Poly
  for i in 0 ..< n:
    work[i] = input[2 + i]
    if work[i] < 0 or work[i] >= Modulus: return -1
  for i in 0 ..< m:
    let coefficient = input[2 + n + i]
    if coefficient < 0 or coefficient >= Modulus: return -1
  if work[n - 1] == 0 or input[2 + n + m - 1] == 0: return -1

  var quotientBound = 0
  if n >= m:
    quotientBound = n - m + 1
    let inverseLeading = powerMod(input[2 + n + m - 1], Modulus - 2)
    var shiftPlusOne = quotientBound
    while shiftPlusOne > 0:
      let shift = shiftPlusOne - 1
      let factor = work[shift + m - 1] * inverseLeading mod Modulus
      quotient[shift] = factor
      for j in 0 ..< m:
        var value = (work[shift + j] - factor * input[2 + n + j]) mod Modulus
        if value < 0: value += Modulus
        work[shift + j] = value
      dec shiftPlusOne

  let quotientLength = trim(quotient, quotientBound)
  let remainderBound = min(n, m)
  let remainderLength = trim(work, remainderBound)
  let bytes = 8 * (2 + quotientLength + remainderLength)
  if bytes > MaxOutputBytes: return -1
  if output.isNil or int(capacity) < bytes: return -2

  storeLe(output, 0, int64(quotientLength))
  storeLe(output, 8, int64(remainderLength))
  var offset = 16
  for i in 0 ..< quotientLength:
    storeLe(output, offset, quotient[i])
    offset += 8
  for i in 0 ..< remainderLength:
    storeLe(output, offset, work[i])
    offset += 8
  int64(bytes)
