const MaxLimit = 5000
const MaxParseableLength = 2

proc modularPower(baseValue, exponentValue, modulus: int64): int64 =
  var base = baseValue
  var exponent = exponentValue
  result = 1
  while exponent > 0:
    if (exponent and 1) != 0: result = (result * base) mod modulus
    base = (base * base) mod modulus
    exponent = exponent shr 1

proc countWieferich(limit: int): int64 =
  var prime: array[MaxLimit + 1, uint8]
  for n in 0 .. limit: prime[n] = 1
  prime[0] = 0
  prime[1] = 0
  var divisor = 2
  while divisor * divisor <= limit:
    if prime[divisor] != 0:
      var multiple = divisor * divisor
      while multiple <= limit:
        prime[multiple] = 0
        multiple += divisor
    inc divisor
  var count = 0'i64
  var p = 3
  while p <= limit:
    if prime[p] != 0:
      let p64 = int64(p)
      if modularPower(2, p64 - 1, p64 * p64) == 1: inc count
    p += 2
  count

proc wieferich_prime_count_up_to_limit*(input: ptr UncheckedArray[int64],
    length: csize_t): int64 {.cdecl, exportc: "wieferich_prime_count_up_to_limit".} =
  if input.isNil or length < 1 or length > csize_t(MaxParseableLength): return -1
  if length != 1 or input[0] < 2 or input[0] > MaxLimit: return -1
  countWieferich(int(input[0]))
