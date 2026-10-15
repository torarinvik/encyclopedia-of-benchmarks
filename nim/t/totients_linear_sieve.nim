## Encode phi(1) through phi(n) as comma-separated decimal bytes.
proc decimalLength(value: int64): csize_t =
  var remaining = value
  var length = csize_t(1)
  while remaining >= 10:
    remaining = remaining div 10
    inc length
  length

proc appendDecimal(valueInput: int64, output: ptr UncheckedArray[uint8], positionInput: csize_t): csize_t =
  var value = valueInput
  var digits: array[3, uint8]
  var count = 0
  while true:
    digits[count] = uint8(value mod 10)
    inc count
    value = value div 10
    if value == 0: break
  var position = positionInput
  while count > 0:
    dec count
    output[position] = uint8(ord('0')) + digits[count]
    inc position
  position

proc totients_linear_sieve*(n: int64, output: ptr UncheckedArray[uint8],
                            outputCapacity: csize_t): int64 {.cdecl, exportc: "totients_linear_sieve".} =
  if n < 1 or n > 80: return -1
  var phi: array[81, int64]
  var composite: array[81, int64]
  var primes: array[80, int64]
  var primeCount = 0
  phi[1] = 1
  var i = 2
  while i <= int(n):
    if composite[i] == 0:
      primes[primeCount] = int64(i)
      inc primeCount
      phi[i] = int64(i - 1)
    var j = 0
    while j < primeCount:
      let p = int(primes[j])
      if i * p > int(n): break
      composite[i * p] = 1
      if i mod p == 0:
        phi[i * p] = phi[i] * int64(p)
        break
      phi[i * p] = phi[i] * int64(p - 1)
      inc j
    inc i
  var required = csize_t(n - 1)
  for index in 1 .. int(n): required += decimalLength(phi[index])
  if output.isNil or outputCapacity < required: return -2
  var position = csize_t(0)
  for index in 1 .. int(n):
    if index > 1:
      output[position] = uint8(ord(','))
      inc position
    position = appendDecimal(phi[index], output, position)
  int64(position)
