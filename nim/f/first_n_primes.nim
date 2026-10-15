## Encode the first n primes in ascending order as comma-separated decimal bytes.
proc isPrime(value: int64): bool =
  if value < 2: return false
  var divisor = 2'i64
  while divisor <= value div divisor:
    if value mod divisor == 0: return false
    inc divisor
  true

proc decimalLength(value: int64): csize_t =
  var remaining = value
  var length = csize_t(1)
  while remaining >= 10:
    remaining = remaining div 10
    inc length
  length

proc requiredLength(numberOfPrimes: int64): csize_t =
  var length = csize_t(0)
  var count = csize_t(0)
  var value = 2'i64
  while count < csize_t(numberOfPrimes):
    if isPrime(value):
      length += decimalLength(value)
      if count > 0: inc length
      inc count
    inc value
  length

proc appendDecimal(value: int64, output: ptr UncheckedArray[uint8],
    positionValue: csize_t): csize_t =
  var digits: array[3, uint8]
  var count = 0
  var remaining = value
  while remaining > 0:
    digits[count] = uint8(remaining mod 10)
    inc count
    remaining = remaining div 10
  var position = positionValue
  while count > 0:
    dec count
    output[position] = uint8('0') + digits[count]
    inc position
  position

proc first_n_primes*(numberOfPrimes: int64, output: ptr UncheckedArray[uint8],
    outputCapacity: csize_t): int64 {.cdecl, exportc: "first_n_primes".} =
  if numberOfPrimes < 0 or numberOfPrimes > 20: return -1
  let required = requiredLength(numberOfPrimes)
  if output == nil or outputCapacity < required: return -2
  var position = csize_t(0)
  var count = csize_t(0)
  var value = 2'i64
  while count < csize_t(numberOfPrimes):
    if isPrime(value):
      if count > 0:
        output[position] = uint8(',')
        inc position
      position = appendDecimal(value, output, position)
      inc count
    inc value
  int64(position)
