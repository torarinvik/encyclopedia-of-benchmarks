const
  Modulus = 998_244_353'i64
  MaxExponent = 1_000_000_000_000_000_000'i64
  MaxN = 32
  MaxInput = 34

type Polynomial = array[MaxN, int64]

proc multiplyTruncated(left, right: Polynomial, n: int): Polynomial =
  var product: Polynomial
  for i in 0 ..< n:
    for j in 0 ..< n - i:
      product[i + j] = (product[i + j] + left[i] * right[j]) mod Modulus
  product

proc storeLe(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc pow_of_formal_power_series*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "pow_of_formal_power_series".} =
  if input.isNil or length < csize_t(3) or length > csize_t(MaxInput): return -1
  let nValue = input[0]
  let exponentInput = input[1]
  if nValue < 1 or nValue > MaxN.int64 or exponentInput < 0 or exponentInput > MaxExponent: return -1
  let n = nValue.int
  if length != csize_t(n + 2): return -1
  for i in 0 ..< n:
    if input[i + 2] < 0 or input[i + 2] >= Modulus: return -1

  let bytes = 8 * n
  if output.isNil or capacity < csize_t(bytes): return -2
  var result: Polynomial
  var base: Polynomial
  result[0] = 1
  for i in 0 ..< n: base[i] = input[i + 2]
  var exponent = exponentInput
  while exponent > 0:
    if (exponent and 1) != 0: result = multiplyTruncated(result, base, n)
    exponent = exponent shr 1
    if exponent > 0: base = multiplyTruncated(base, base, n)
  for i in 0 ..< n: storeLe(output, 8 * i, result[i])
  int64(bytes)
