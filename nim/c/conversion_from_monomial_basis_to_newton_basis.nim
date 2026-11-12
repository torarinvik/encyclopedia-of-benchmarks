const
  Modulus = 998_244_353'i64
  MaxN = 12
  MaxInput = 25
  Capacity = 12

type Coefficients = array[Capacity, int64]

proc storeLe(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc conversion_from_monomial_basis_to_newton_basis*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "conversion_from_monomial_basis_to_newton_basis".} =
  if input.isNil or length < csize_t(3) or length > csize_t(MaxInput): return -1
  let nValue = input[0]
  if nValue < 1 or nValue > MaxN.int64: return -1
  let n = nValue.int
  if length != csize_t(1 + 2 * n): return -1
  for i in 0 ..< 2 * n:
    if input[i + 1] < 0 or input[i + 1] >= Modulus: return -1

  let bytes = 8 * n
  if output.isNil or capacity < csize_t(bytes): return -2
  var residual: Coefficients
  var answer: Coefficients
  for i in 0 ..< n: residual[i] = input[i + 1]

  var active = n
  for i in 0 ..< n:
    let node = input[n + 1 + i]
    var value = 0'i64
    for degree in countdown(active - 1, 0):
      value = (value * node + residual[degree]) mod Modulus
    answer[i] = value
    if active == 1: continue

    var quotient: Coefficients
    quotient[active - 2] = residual[active - 1]
    var degree = active - 2
    while degree > 0:
      quotient[degree - 1] = (residual[degree] + node * quotient[degree]) mod Modulus
      dec degree
    for j in 0 ..< active - 1: residual[j] = quotient[j]
    dec active
  for i in 0 ..< n: storeLe(output, 8 * i, answer[i])
  int64(bytes)
