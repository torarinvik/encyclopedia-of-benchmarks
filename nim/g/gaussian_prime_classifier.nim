type
  I64Input = ptr UncheckedArray[int64]

const
  MaxCoordinate = 10_000'i64

proc gpRationalPrime(value: int64): bool =
  if value < 2: return false
  if value mod 2 == 0: return value == 2
  var divisor = 3'i64
  while divisor <= value div divisor:
    if value mod divisor == 0: return false
    divisor += 2
  true

proc gaussian_prime_classifier*(values: I64Input, length: csize_t): int64
    {.cdecl, exportc: "gaussian_prime_classifier".} =
  if values == nil or length < 1 or length > 3: return -1
  if length != 2: return -1
  let real = values[0]
  let imaginary = values[1]
  if real < -MaxCoordinate or real > MaxCoordinate or
     imaginary < -MaxCoordinate or imaginary > MaxCoordinate: return -1
  if real == 0 and imaginary == 0: return 0
  if real == 0 or imaginary == 0:
    let axis = if real == 0: imaginary else: real
    let rational = if axis < 0: -axis else: axis
    if rational mod 4 == 3 and gpRationalPrime(rational): return 1
    return 0
  let norm = real * real + imaginary * imaginary
  if gpRationalPrime(norm): return 1
  0'i64
