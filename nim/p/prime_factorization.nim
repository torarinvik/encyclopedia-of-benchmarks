## Encode ascending prime/exponent pairs as little-endian u32 values.
proc factorPairs(value: int64, primes, exponents: var array[10, uint32]): int =
  var count = 0
  var remaining = value
  var divisor = 2'i64
  while divisor <= remaining div divisor:
    if remaining mod divisor == 0:
      var exponent = 0'u32
      while remaining mod divisor == 0:
        remaining = remaining div divisor
        inc exponent
      primes[count] = uint32(divisor)
      exponents[count] = exponent
      inc count
    inc divisor
  if remaining > 1:
    primes[count] = uint32(remaining)
    exponents[count] = 1
    inc count
  count

proc writeU32Le(value: uint32, output: ptr UncheckedArray[uint8], position: int) =
  for byte in 0 ..< 4:
    output[position + byte] = uint8((value shr (8 * byte)) and 255)

proc prime_factorization*(value: int64, output: ptr UncheckedArray[uint8],
    outputCapacity: csize_t): int64 {.cdecl, exportc: "prime_factorization".} =
  if value < 1 or value > 1_000_005: return -1
  var primes, exponents: array[10, uint32]
  let count = factorPairs(value, primes, exponents)
  let required = count * 8
  if output == nil or outputCapacity < csize_t(required): return -2
  for index in 0 ..< count:
    writeU32Le(primes[index], output, 8 * index)
    writeU32Le(exponents[index], output, 8 * index + 4)
  int64(required)
