const
  Modulus = 998_244_353'i64
  MaxN = 16
  MaxM = 16
  MaxInput = 20

type ShiftArray = array[MaxN, int64]

proc modPow(baseValue, exponentValue: int64): int64 =
  var base = baseValue
  var exponent = exponentValue
  result = 1
  while exponent > 0:
    if (exponent and 1) != 0: result = result * base mod Modulus
    base = base * base mod Modulus
    exponent = exponent shr 1

proc storeLe(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc shift_of_sampling_points_of_polynomial*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "shift_of_sampling_points_of_polynomial".} =
  if input.isNil or length < csize_t(4) or length > csize_t(MaxInput): return -1
  let nValue = input[0]
  let mValue = input[1]
  let start = input[2]
  if nValue < 1 or nValue > MaxN.int64 or mValue < 1 or mValue > MaxM.int64: return -1
  let n = nValue.int
  let m = mValue.int
  if length != csize_t(n + 3) or start < 0 or start >= Modulus: return -1
  for i in 0 ..< n:
    if input[i + 3] < 0 or input[i + 3] >= Modulus: return -1

  let bytes = 8 * m
  if output.isNil or capacity < csize_t(bytes): return -2
  var differences, newton, factorial, inverseFactorial: ShiftArray
  for i in 0 ..< n: differences[i] = input[i + 3]
  factorial[0] = 1
  for k in 1 ..< n: factorial[k] = factorial[k - 1] * k.int64 mod Modulus
  inverseFactorial[n - 1] = modPow(factorial[n - 1], Modulus - 2)
  for k in countdown(n - 1, 1): inverseFactorial[k - 1] = inverseFactorial[k] * k.int64 mod Modulus
  for k in 0 ..< n:
    newton[k] = differences[0] * inverseFactorial[k] mod Modulus
    for i in 0 ..< n - k - 1:
      differences[i] = differences[i + 1] - differences[i]
      if differences[i] < 0: differences[i] += Modulus

  for offset in 0 ..< m:
    var x = start + offset.int64
    if x >= Modulus: x -= Modulus
    var basis = 1'i64
    var value = 0'i64
    for k in 0 ..< n:
      value = (value + newton[k] * basis) mod Modulus
      var factor = x - k.int64
      if factor < 0: factor += Modulus
      basis = basis * factor mod Modulus
    storeLe(output, 8 * offset, value)
  int64(bytes)
