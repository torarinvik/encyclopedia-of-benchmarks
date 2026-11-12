const
  Modulus = 998_244_353'i64
  MaxN = 64
  MaxInput = 66

proc storeLe(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc log_of_formal_power_series*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "log_of_formal_power_series".} =
  if input == nil or length < 2 or length > csize_t(MaxInput): return -1
  let nValue = input[0]
  if nValue < 1 or nValue > MaxN: return -1
  let n = int(nValue)
  if int(length) != n + 1: return -1
  for i in 0 ..< n:
    if input[i + 1] < 0 or input[i + 1] >= Modulus: return -1
  if input[1] != 1: return -1
  let bytes = 8 * n
  if output == nil or int(capacity) < bytes: return -2

  var integerInverse, logarithm: array[MaxN, int64]
  if n > 1: integerInverse[1] = 1
  for k in 2 ..< n:
    integerInverse[k] = Modulus - (Modulus div int64(k)) *
      integerInverse[int(Modulus mod int64(k))] mod Modulus
  for degree in 1 ..< n:
    var numerator = (int64(degree) * input[degree + 1]) mod Modulus
    for i in 1 ..< degree:
      var term = (int64(i) * logarithm[i]) mod Modulus
      term = term * input[degree - i + 1] mod Modulus
      numerator = (numerator - term) mod Modulus
      if numerator < 0: numerator += Modulus
    logarithm[degree] = numerator * integerInverse[degree] mod Modulus
  for i in 0 ..< n: storeLe(output, 8 * i, logarithm[i])
  int64(bytes)
